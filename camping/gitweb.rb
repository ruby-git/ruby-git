require 'rubygems'
require 'camping'
require 'lib/git'

#
# gitweb is a web frontend on git
# there is no user auth, so don't run this anywhere that anyone can use it
# it's read only, but anyone can remove or add references to your repos
#
# everything but the archive and diff functions are now in pure ruby
#
# install dependencies
#   sudo gem install camping-omnibus --source http://code.whytheluckystiff.net
#
# todo
#   - diff/patch between any two objects
#     - expand patch to entire file
#   - set title properly
#   - grep / search function
#   - prettify : http://projects.wh.techno-weenie.net/changesets/3030
#   - add user model (add/remove repos)
#   - implement http-push for authenticated users 
#
# author : scott chacon
#

Camping.goes :GitWeb

module GitWeb::Models
  class Repository < Base; end
  
  class CreateGitWeb < V 0.1
    def self.up
      create_table :gitweb_repositories, :force => true do |t|
        t.column :name,  :string 
        t.column :path,  :string 
        t.column :bare,  :boolean 
      end
    end
  end
end

module GitWeb::Helpers
  def inline_data(identifier)
    section = "__#{identifier.to_s.upcase}__"
    @@inline_data ||= File.read(__FILE__).gsub(/.*__END__/m, '')
    data = @@inline_data.match(/(#{section}.)(.*?)((__)|(\Z))/m)
    data ? data[2] : nil # return nil if no second found
  end
end

module GitWeb::Controllers

  class Stylesheet < R '/css/highlight.css'
    def get
      @headers['Content-Type'] = 'text/css'
      inline_data(:css)
    end
  end
  
  class JsHighlight < R '/js/highlight.js'
    def get
      @headers['Content-Type'] = 'text/javascript'
      inline_data(:js)
    end
  end
  
  
  class Index < R '/'
    def get
      @repos = Repository.find :all
      render :index
    end
  end
    
  class Add < R '/add'
    def get
      @repo = Repository.new
      render :add
    end
    def post
      if Git.bare(input.repository_path)
        repo = Repository.create :name => input.repo_name, :path => input.repo_path, :bare => input.repo_bare
        redirect View, repo
      else
        redirect Index
      end
    end
  end
  
  class RemoveRepo < R '/remove/(\d+)'
    def get repo_id
      @repo = Repository.find repo_id
      @repo.destroy
      @repos = Repository.find :all
      render :index
    end
  end
  
  
  class View < R '/view/(\d+)'
    def get repo_id
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)     
      render :view
    end
  end
  
  class Fetch < R '/git/(\d+)/(.*)'
    def get repo_id, path
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
      File.read(File.join(@git.repo.path, path))
    end
  end
  
  class Commit < R '/commit/(\d+)/(\w+)'
    def get repo_id, sha
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)   
      @commit = @git.gcommit(sha)
      render :commit
    end
  end
  
  class Tree < R '/tree/(\d+)/(\w+)'
    def get repo_id, sha
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)   
      @tree = @git.gtree(sha)
      render :tree
    end
  end
  
  class Blob < R '/blob/(\d+)/(.*?)/(\w+)'
    def get repo_id, file, sha
      @repo = Repository.find repo_id

      #logger = Logger.new('/tmp/git.log')
      #logger.level = Logger::INFO
      #@git = Git.bare(@repo.path, :log => logger)      

      @git = Git.bare(@repo.path)
      @blob = @git.gblob(sha)
      @file = file
      render :blob
    end
  end  
  
  class BlobRaw < R '/blob/(\d+)/(\w+)'
     def get repo_id, sha
       @repo = Repository.find repo_id
       @git = Git.bare(@repo.path)      
       @blob = @git.gblob(sha)
       @blob.contents
     end
  end
  
  class Archive < R '/archive/(\d+)/(\w+)'
    def get repo_id, sha
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
      
      file = @git.gtree(sha).archive
      @headers['Content-Type'] = 'application/zip'
      @headers["Content-Disposition"] = "attachment; filename=archive.zip"
      File.new(file).read
    end
  end

  class Download < R '/download/(\d+)/(.*?)/(\w+)'
    def get repo_id, file, sha
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
      @headers["Content-Disposition"] = "attachment; filename=#{file}"
      @git.gblob(sha).contents
    end
  end
  
  class Diff < R '/diff/(\d+)/(\w+)/(\w+)'
    def get repo_id, tree1, tree2
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
      @tree1 = tree1
      @tree2 = tree2
      @diff = @git.diff(tree2, tree1)
      render :diff
    end
  end
  
  class Patch < R '/patch/(\d+)/(\w+)/(\w+)'
    def get repo_id, tree1, tree2
      @repo = Repository.find repo_id
      @git = Git.bare(@repo.path)
      @diff = @git.diff(tree1, tree2).patch
    end
  end
  
end

module GitWeb::Views
  def layout
    html do
      head do
        title 'test'
        link :href=>R(Stylesheet), :rel=>'stylesheet', :type=>'text/css'
        script '', :type => "text/javascript", :language => "JavaScript", :src => R(JsHighlight)
      end
      style <<-END, :type => 'text/css'
        body { font-family: verdana, arial, helvetica, sans-serif; color: #333; 
                font-size:   13px;
                line-height: 18px;}

        h1 { background: #cce; padding: 10px; margin: 3px; }
        h3 { background: #aea; padding: 5px; margin: 3px; }
        .options { float: right; margin: 10px; }
        p { padding: 5px; }
        .odd { background: #eee; }
        .tag { margin: 5px; padding: 1px 3px; border: 1px solid #8a8; background: #afa;}
        .indent { padding: 0px 15px;}
        table tr td { font-size: 13px; }
        table.shortlog { width: 100%; }
        .timer { color: #666; padding: 10px; margin-top: 10px; }
      END
      body :onload => "sh_highlightDocument();" do
        before = Time.now().usec
        self << yield
        self << '<br/>' + ((Time.now().usec - before).to_f / 60).to_s + ' sec'
      end
    end
  end

  # git repo views
  
  def view
    h1 @repo.name
    h2 @repo.path

    gtags = @git.tags
    @tags = {}
    gtags.each { |tag| @tags[tag.sha] ||= []; @tags[tag.sha] << tag.name }
    
    url = 'http:' + URL(Fetch, @repo.id, '').to_s

    h3 'info'
    table.info do
      tr { td 'owner: '; td @git.config('user.name') }
      tr { td 'email: '; td @git.config('user.email') }
      tr { td 'url: '; td { a url, :href => url } }
    end
    
    h3 'shortlog'
    table.shortlog do
      @git.log.each do |log|
        tr do
          td log.date.strftime("%Y-%m-%d")
          td { code log.sha[0, 8] }
          td { em log.author.name }
          td do
            span.message log.message[0, 60]
            @tags[log.sha].each do |t|
              span.space ' '
              span.tag { code t }
            end if @tags[log.sha]
          end
          td { a 'commit', :href => R(Commit, @repo, log.sha) }
          td { a 'commit-diff', :href => R(Diff, @repo, log.sha, log.parent.sha) }
          td { a 'tree', :href => R(Tree, @repo, log.gtree.sha) }
          td { a 'archive', :href => R(Archive, @repo, log.gtree.sha) }
        end
      end
    end
    
    h3 'branches'
    @git.branches.each do |branch|
      li { a branch.full, :href => R(Commit, @repo, branch.gcommit.sha) }
    end
    
    h3 'tags'
    gtags.each do |tag|
      li { a tag.name, :href => R(Commit, @repo, tag.sha) }
    end
    
  end
  
  def commit
    a.options 'repo', :href => R(View, @repo)
    h1 @commit.name
    h3 'info'
    table.info do
      tr { td 'author: '; td @commit.author.name + ' <' + @commit.author.email + '>'}
      tr { td ''; td { code @commit.author.date } }
      tr { td 'committer: '; td @commit.committer.name + ' <' + @commit.committer.email + '>'}
      tr { td ''; td { code @commit.committer.date } }
      tr { td 'commit sha: '; td { code @commit.sha } }
      tr do
        td 'tree sha: '
        td do 
          code { a @commit.gtree.sha, :href => R(Tree, @repo, @commit.gtree.sha) }
          span.space ' '
          a 'archive', :href => R(Archive, @repo, @commit.gtree.sha)
        end
      end
      tr do
        td 'parents: '
        td do
          @commit.parents.each do |p|
            code { a p.sha, :href => R(Commit, @repo, p.sha) }
            span.space ' '
            a 'diff', :href => R(Diff, @repo, p.sha, @commit.sha)
            span.space ' '
            a 'archive', :href => R(Archive, @repo, p.gtree.sha)            
            br
          end
        end
      end
    end
    h3 'commit message'
    p @commit.message
  end
  
  def tree
    a.options 'repo', :href => R(View, @repo)
    h3 'tree : ' + @tree.sha
    p { a 'archive tree', :href => R(Archive, @repo, @tree.sha) }; 
    table do
      @tree.children.each do |file, node|
        tr :class => cycle('odd','even') do
          td { code node.sha[0, 8] }
          td node.mode
          td file
          if node.type == 'tree'
            td { a node.type, :href => R(Tree, @repo, node.sha) }
            td { a 'archive', :href => R(Archive, @repo, node.sha) }
          else
            td { a node.type, :href => R(Blob, @repo, file, node.sha) }
            td { a 'raw', :href => R(BlobRaw, @repo, node.sha) }
          end
        end
      end
    end 
  end

  def blob
    ext = File.extname(@file).gsub('.', '')
    
    case ext
      when 'rb' : classnm = 'sh_ruby'
      when 'js' : classnm = 'sh_javascript'
      when 'html' : classnm = 'sh_html'
      when 'css' : classnm = 'sh_css'
    end
    
    a.options 'repo', :href => R(View, @repo)
    h3 'blob : ' + @blob.sha
    h4 @file
    
    a 'download file', :href => R(Download, @repo, @file, @blob.sha)
    
    div.indent { pre @blob.contents, :class => classnm }
  end
  
  def diff
    a.options 'repo', :href => R(View, @repo)    
    h1 "diff"

    p { a 'download patch file', :href => R(Patch, @repo, @tree1, @tree2) }

    p do
      a @tree1, :href => R(Tree, @repo, @tree1)
      span.space ' : '
      a @tree2, :href => R(Tree, @repo, @tree2)
    end
    
    @diff.each do |file|
      h3 file.path
      div.indent { pre file.patch, :class => 'sh_diff' }
    end
  end
  
  # repo management views
  
  def add
    _form(@repo)
  end
  
  def _form(repo)
    form(:method => 'post') do
      label 'Path', :for => 'repo_path'; br
      input :name => 'repo_path', :type => 'text', :value => repo.path; br

      label 'Name', :for => 'repo_name'; br
      input :name => 'repo_name', :type => 'text', :value => repo.name; br

      label 'Bare', :for => 'repo_bare'; br
      input :type => 'checkbox', :name => 'repo_bare', :value => repo.bare; br

      input :type => 'hidden', :name => 'repo_id', :value => repo.id
      input :type => 'submit'
    end
  end
  
  def index
    @repos.each do | repo |
      h1 repo.name
      a 'remove', :href => R(RemoveRepo, repo.id)
      span.space ' '
      a repo.path, :href => R(View, repo.id)
    end
    br
    br
    a 'add new repo', :href => R(Add)
  end
  
  # convenience functions
  
  def cycle(v1, v2)
    (@value == v1) ? @value = v2 : @value = v1
    @value
  end
  
end

def GitWeb.create
  GitWeb::Models.create_schema
end

# everything below this line is the css and javascript for syntax-highlighting
__END__

__CSS__
pre.sh_sourceCode {
  background-color: white;
  color: black;
  font-style: normal;
  font-weight: normal;
}

pre.sh_sourceCode .sh_keyword { color: blue; font-weight: bold; }           /* language keywords */
pre.sh_sourceCode .sh_type { color: darkgreen; }                            /* basic types */
pre.sh_sourceCode .sh_string { color: red; font-family: monospace; }        /* strings and chars */
pre.sh_sourceCode .sh_regexp { color: orange; font-family: monospace; }     /* regular expressions */
pre.sh_sourceCode .sh_specialchar { color: pink; font-family: monospace; }  /* e.g., \n, \t, \\ */
pre.sh_sourceCode .sh_comment { color: brown; font-style: italic; }         /* comments */
pre.sh_sourceCode .sh_number { color: purple; }                             /* literal numbers */
pre.sh_sourceCode .sh_preproc { color: darkblue; font-weight: bold; }       /* e.g., #include, import */
pre.sh_sourceCode .sh_symbol { color: darkred; }                            /* e.g., <, >, + */
pre.sh_sourceCode .sh_function { color: black; font-weight: bold; }         /* function calls and declarations */
pre.sh_sourceCode .sh_cbracket { color: red; }                              /* block brackets (e.g., {, }) */
pre.sh_sourceCode .sh_todo { font-weight: bold; background-color: cyan; }   /* TODO and FIXME */

/* for Perl, PHP, Prolog, Python, shell, Tcl */
pre.sh_sourceCode .sh_variable { color: darkgreen; }

/* line numbers (not yet implemented) */
pre.sh_sourceCode .sh_linenum { color: black; font-family: monospace; }

/* Internet related */
pre.sh_sourceCode .sh_url { color: blue; text-decoration: underline; font-family: monospace; }

/* for ChangeLog and Log files */
pre.sh_sourceCode .sh_date { color: blue; font-weight: bold; }
pre.sh_sourceCode .sh_time, pre.sh_sourceCode .sh_file { color: darkblue; font-weight: bold; }
pre.sh_sourceCode .sh_ip, pre.sh_sourceCode .sh_name { color: darkgreen; }

/* for LaTeX */
pre.sh_sourceCode .sh_italics { color: darkgreen; font-style: italic; }
pre.sh_sourceCode .sh_bold { color: darkgreen; font-weight: bold; }
pre.sh_sourceCode .sh_underline { color: darkgreen; text-decoration: underline; }
pre.sh_sourceCode .sh_fixed { color: green; font-family: monospace; }
pre.sh_sourceCode .sh_argument { color: darkgreen; }
pre.sh_sourceCode .sh_optionalargument { color: purple; }
pre.sh_sourceCode .sh_math { color: orange; }
pre.sh_sourceCode .sh_bibtex { color: blue; }

/* for diffs */
pre.sh_sourceCode .sh_oldfile { color: orange; }
pre.sh_sourceCode .sh_newfile { color: darkgreen; }
pre.sh_sourceCode .sh_difflines { color: blue; }

/* for css */
pre.sh_sourceCode .sh_selector { color: purple; }
pre.sh_sourceCode .sh_property { color: blue; }
pre.sh_sourceCode .sh_value { color: darkgreen; font-style: italic; }

__JS__

/* Copyright (C) 2007 gnombat@users.sourceforge.net */
/* License: http://shjs.sourceforge.net/doc/license.html */

function sh_highlightString(inputString,language,builder){var patternStack={_stack:[],getLength:function(){return this._stack.length;},getTop:function(){var stack=this._stack;var length=stack.length;if(length===0){return undefined;}
return stack[length-1];},push:function(state){this._stack.push(state);},pop:function(){if(this._stack.length===0){throw"pop on empty stack";}
this._stack.pop();}};var pos=0;var currentStyle=undefined;var output=function(s,style){var length=s.length;if(length===0){return;}
if(!style){var pattern=patternStack.getTop();if(pattern!==undefined&&!('state'in pattern)){style=pattern.style;}}
if(currentStyle!==style){if(currentStyle){builder.endElement();}
if(style){builder.startElement(style);}}
builder.text(s);pos+=length;currentStyle=style;};var endOfLinePattern=/\r\n|\r|\n/g;endOfLinePattern.lastIndex=0;var inputStringLength=inputString.length;while(pos<inputStringLength){var start=pos;var end;var startOfNextLine;var endOfLineMatch=endOfLinePattern.exec(inputString);if(endOfLineMatch===null){end=inputStringLength;startOfNextLine=inputStringLength;}
else{end=endOfLineMatch.index;startOfNextLine=endOfLinePattern.lastIndex;}
var line=inputString.substring(start,end);var matchCache=null;var matchCacheState=-1;for(;;){var posWithinLine=pos-start;var pattern=patternStack.getTop();var stateIndex=pattern===undefined?0:pattern.next;var state=language[stateIndex];var numPatterns=state.length;if(stateIndex!==matchCacheState){matchCache=[];}
var bestMatch=null;var bestMatchIndex=-1;for(var i=0;i<numPatterns;i++){var match;if(stateIndex===matchCacheState&&(matchCache[i]===null||posWithinLine<=matchCache[i].index)){match=matchCache[i];}
else{var regex=state[i].regex;regex.lastIndex=posWithinLine;match=regex.exec(line);matchCache[i]=match;}
if(match!==null&&(bestMatch===null||match.index<bestMatch.index)){bestMatch=match;bestMatchIndex=i;}}
matchCacheState=stateIndex;if(bestMatch===null){output(line.substring(posWithinLine),null);break;}
else{if(bestMatch.index>posWithinLine){output(line.substring(posWithinLine,bestMatch.index),null);}
pattern=state[bestMatchIndex];var newStyle=pattern.style;var matchedString;if(newStyle instanceof Array){for(var subexpression=0;subexpression<newStyle.length;subexpression++){matchedString=bestMatch[subexpression+1];output(matchedString,newStyle[subexpression]);}}
else{matchedString=bestMatch[0];output(matchedString,newStyle);}
if('next'in pattern){patternStack.push(pattern);}
else{if('exit'in pattern){patternStack.pop();}
if('exitall'in pattern){while(patternStack.getLength()>0){patternStack.pop();}}}}}
if(currentStyle){builder.endElement();}
currentStyle=undefined;if(endOfLineMatch){builder.text(endOfLineMatch[0]);}
pos=startOfNextLine;}}
function sh_getClasses(element){var result=[];var htmlClass=element.className;if(htmlClass&&htmlClass.length>0){var htmlClasses=htmlClass.split(" ");for(var i=0;i<htmlClasses.length;i++){if(htmlClasses[i].length>0){result.push(htmlClasses[i]);}}}
return result;}
function sh_addClass(element,name){var htmlClasses=sh_getClasses(element);for(var i=0;i<htmlClasses.length;i++){if(name.toLowerCase()===htmlClasses[i].toLowerCase()){return;}}
htmlClasses.push(name);element.className=htmlClasses.join(" ");}
function sh_getText(element){if(element.nodeType===3||element.nodeType===4){return element.data;}
else if(element.childNodes.length===1){return sh_getText(element.firstChild);}
else{var result='';for(var i=0;i<element.childNodes.length;i++){result+=sh_getText(element.childNodes.item(i));}
return result;}}
function sh_isEmailAddress(url){if(/^mailto:/.test(url)){return false;}
return url.indexOf('@')!==-1;}
var sh_builder={init:function(htmlDocument,element){while(element.hasChildNodes()){element.removeChild(element.firstChild);}
this._document=htmlDocument;this._element=element;this._currentText=null;this._documentFragment=htmlDocument.createDocumentFragment();this._currentParent=this._documentFragment;this._span=htmlDocument.createElement("span");this._a=htmlDocument.createElement("a");},startElement:function(style){if(this._currentText!==null){this._currentParent.appendChild(this._document.createTextNode(this._currentText));this._currentText=null;}
var span=this._span.cloneNode(true);span.className=style;this._currentParent.appendChild(span);this._currentParent=span;},endElement:function(){if(this._currentText!==null){if(this._currentParent.className==='sh_url'){var a=this._a.cloneNode(true);a.className='sh_url';var url=this._currentText;if(url.length>0&&url.charAt(0)==='<'&&url.charAt(url.length-1)==='>'){url=url.substr(1,url.length-2);}
if(sh_isEmailAddress(url)){url='mailto:'+url;}
a.setAttribute('href',url);a.appendChild(this._document.createTextNode(this._currentText));this._currentParent.appendChild(a);}
else{this._currentParent.appendChild(this._document.createTextNode(this._currentText));}
this._currentText=null;}
this._currentParent=this._currentParent.parentNode;},text:function(s){if(this._currentText===null){this._currentText=s;}
else{this._currentText+=s;}},close:function(){if(this._currentText!==null){this._currentParent.appendChild(this._document.createTextNode(this._currentText));this._currentText=null;}
this._element.appendChild(this._documentFragment);}};function sh_highlightElement(htmlDocument,element,language){sh_addClass(element,"sh_sourceCode");var inputString;if(element.childNodes.length===0){return;}
else{inputString=sh_getText(element);}
sh_builder.init(htmlDocument,element);sh_highlightString(inputString,language,sh_builder);sh_builder.close();}
function sh_highlightHTMLDocument(htmlDocument){if(!window.sh_languages){return;}
var nodeList=htmlDocument.getElementsByTagName("pre");for(var i=0;i<nodeList.length;i++){var element=nodeList.item(i);var htmlClasses=sh_getClasses(element);for(var j=0;j<htmlClasses.length;j++){var htmlClass=htmlClasses[j].toLowerCase();if(htmlClass==="sh_sourcecode"){continue;}
var prefix=htmlClass.substr(0,3);if(prefix==="sh_"){var language=htmlClass.substring(3);if(language in sh_languages){sh_highlightElement(htmlDocument,element,sh_languages[language]);}
else{throw"Found <pre> element with class='"+htmlClass+"', but no such language exists";}}}}}
function sh_highlightDocument(){sh_highlightHTMLDocument(document);}

if(!this.sh_languages){this.sh_languages={};}
sh_languages['css']=[[{'next':1,'regex':/\/\/\//g,'style':'sh_comment'},{'next':7,'regex':/\/\//g,'style':'sh_comment'},{'next':8,'regex':/\/\*\*/g,'style':'sh_comment'},{'next':14,'regex':/\/\*/g,'style':'sh_comment'},{'regex':/(?:\.|#)[A-Za-z0-9_]+/g,'style':'sh_selector'},{'next':15,'regex':/\{/g,'state':1,'style':'sh_cbracket'},{'regex':/~|!|%|\^|\*|\(|\)|-|\+|=|\[|\]|\\|:|;|,|\.|\/|\?|&|<|>|\|/g,'style':'sh_symbol'}],[{'exit':true,'regex':/$/g},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'next':2,'regex':/<!DOCTYPE/g,'state':1,'style':'sh_preproc'},{'next':4,'regex':/<!--/g,'style':'sh_comment'},{'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'style':'sh_keyword'},{'next':5,'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'state':1,'style':'sh_keyword'},{'regex':/&(?:[A-Za-z0-9]+);/g,'style':'sh_preproc'},{'regex':/@[A-Za-z]+/g,'style':'sh_type'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}],[{'exit':true,'regex':/>/g,'style':'sh_preproc'},{'next':3,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/-->/g,'style':'sh_comment'},{'next':4,'regex':/<!--/g,'style':'sh_comment'}],[{'exit':true,'regex':/(?:\/)?>/g,'style':'sh_keyword'},{'regex':/[^=" \t>]+/g,'style':'sh_type'},{'regex':/=/g,'style':'sh_symbol'},{'next':6,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/\*\//g,'style':'sh_comment'},{'next':8,'regex':/\/\*\*/g,'style':'sh_comment'},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'next':9,'regex':/<!DOCTYPE/g,'state':1,'style':'sh_preproc'},{'next':11,'regex':/<!--/g,'style':'sh_comment'},{'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'style':'sh_keyword'},{'next':12,'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'state':1,'style':'sh_keyword'},{'regex':/&(?:[A-Za-z0-9]+);/g,'style':'sh_preproc'},{'regex':/@[A-Za-z]+/g,'style':'sh_type'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}],[{'exit':true,'regex':/>/g,'style':'sh_preproc'},{'next':10,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/-->/g,'style':'sh_comment'},{'next':11,'regex':/<!--/g,'style':'sh_comment'}],[{'exit':true,'regex':/(?:\/)?>/g,'style':'sh_keyword'},{'regex':/[^=" \t>]+/g,'style':'sh_type'},{'regex':/=/g,'style':'sh_symbol'},{'next':13,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/\*\//g,'style':'sh_comment'},{'next':14,'regex':/\/\*/g,'style':'sh_comment'},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}],[{'exit':true,'regex':/\}/g,'style':'sh_cbracket'},{'next':16,'regex':/\/\/\//g,'style':'sh_comment'},{'next':22,'regex':/\/\//g,'style':'sh_comment'},{'next':23,'regex':/\/\*\*/g,'style':'sh_comment'},{'next':29,'regex':/\/\*/g,'style':'sh_comment'},{'regex':/[A-Za-z0-9_-]+[ \t]*:/g,'style':'sh_property'},{'regex':/[.%A-Za-z0-9_-]+/g,'style':'sh_value'},{'regex':/#(?:[A-Za-z0-9_]+)/g,'style':'sh_string'}],[{'exit':true,'regex':/$/g},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'next':17,'regex':/<!DOCTYPE/g,'state':1,'style':'sh_preproc'},{'next':19,'regex':/<!--/g,'style':'sh_comment'},{'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'style':'sh_keyword'},{'next':20,'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'state':1,'style':'sh_keyword'},{'regex':/&(?:[A-Za-z0-9]+);/g,'style':'sh_preproc'},{'regex':/@[A-Za-z]+/g,'style':'sh_type'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}],[{'exit':true,'regex':/>/g,'style':'sh_preproc'},{'next':18,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/-->/g,'style':'sh_comment'},{'next':19,'regex':/<!--/g,'style':'sh_comment'}],[{'exit':true,'regex':/(?:\/)?>/g,'style':'sh_keyword'},{'regex':/[^=" \t>]+/g,'style':'sh_type'},{'regex':/=/g,'style':'sh_symbol'},{'next':21,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/\*\//g,'style':'sh_comment'},{'next':23,'regex':/\/\*\*/g,'style':'sh_comment'},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'next':24,'regex':/<!DOCTYPE/g,'state':1,'style':'sh_preproc'},{'next':26,'regex':/<!--/g,'style':'sh_comment'},{'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'style':'sh_keyword'},{'next':27,'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'state':1,'style':'sh_keyword'},{'regex':/&(?:[A-Za-z0-9]+);/g,'style':'sh_preproc'},{'regex':/@[A-Za-z]+/g,'style':'sh_type'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}],[{'exit':true,'regex':/>/g,'style':'sh_preproc'},{'next':25,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/-->/g,'style':'sh_comment'},{'next':26,'regex':/<!--/g,'style':'sh_comment'}],[{'exit':true,'regex':/(?:\/)?>/g,'style':'sh_keyword'},{'regex':/[^=" \t>]+/g,'style':'sh_type'},{'regex':/=/g,'style':'sh_symbol'},{'next':28,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/\*\//g,'style':'sh_comment'},{'next':29,'regex':/\/\*/g,'style':'sh_comment'},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}]];

if(!this.sh_languages){this.sh_languages={};}
sh_languages['diff']=[[{'next':1,'regex':/(?=^[-]{3})/g,'state':1,'style':'sh_oldfile'},{'next':6,'regex':/(?=^[*]{3})/g,'state':1,'style':'sh_oldfile'},{'next':14,'regex':/(?=^[\d])/g,'state':1,'style':'sh_difflines'}],[{'next':2,'regex':/^[-]{3}/g,'style':'sh_oldfile'},{'next':3,'regex':/^[-]/g,'style':'sh_oldfile'},{'next':4,'regex':/^[+]/g,'style':'sh_newfile'},{'next':5,'regex':/^@@/g,'style':'sh_difflines'}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g}],[{'next':7,'regex':/^[*]{3}[ \t]+[\d]/g,'style':'sh_oldfile'},{'next':9,'regex':/^[*]{3}/g,'style':'sh_oldfile'},{'next':10,'regex':/^[-]{3}[ \t]+[\d]/g,'style':'sh_newfile'},{'next':13,'regex':/^[-]{3}/g,'style':'sh_newfile'}],[{'next':8,'regex':/^[\s]/g,'style':'sh_normal'},{'exit':true,'regex':/(?=^[-]{3})/g,'style':'sh_newfile'}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g}],[{'next':11,'regex':/^[\s]/g,'style':'sh_normal'},{'exit':true,'regex':/(?=^[*]{3})/g,'style':'sh_newfile'},{'exit':true,'next':12,'regex':/^diff/g,'style':'sh_normal'}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g}],[{'next':15,'regex':/^[\d]/g,'style':'sh_difflines'},{'next':16,'regex':/^[<]/g,'style':'sh_oldfile'},{'next':17,'regex':/^[>]/g,'style':'sh_newfile'}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g}]];

if(!this.sh_languages){this.sh_languages={};}
sh_languages['html']=[[{'next':1,'regex':/<!DOCTYPE/g,'state':1,'style':'sh_preproc'},{'next':3,'regex':/<!--/g,'style':'sh_comment'},{'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'style':'sh_keyword'},{'next':4,'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'state':1,'style':'sh_keyword'},{'regex':/&(?:[A-Za-z0-9]+);/g,'style':'sh_preproc'}],[{'exit':true,'regex':/>/g,'style':'sh_preproc'},{'next':2,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/-->/g,'style':'sh_comment'},{'next':3,'regex':/<!--/g,'style':'sh_comment'}],[{'exit':true,'regex':/(?:\/)?>/g,'style':'sh_keyword'},{'regex':/[^=" \t>]+/g,'style':'sh_type'},{'regex':/=/g,'style':'sh_symbol'},{'next':5,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}]];

if(!this.sh_languages){this.sh_languages={};}
sh_languages['javascript']=[[{'regex':/\b(?:import|package)\b/g,'style':'sh_preproc'},{'next':1,'regex':/\/\/\//g,'style':'sh_comment'},{'next':7,'regex':/\/\//g,'style':'sh_comment'},{'next':8,'regex':/\/\*\*/g,'style':'sh_comment'},{'next':14,'regex':/\/\*/g,'style':'sh_comment'},{'regex':/\b[+-]?(?:(?:0x[A-Fa-f0-9]+)|(?:(?:[\d]*\.)?[\d]+(?:[eE][+-]?[\d]+)?))u?(?:(?:int(?:8|16|32|64))|L)?\b/g,'style':'sh_number'},{'next':15,'regex':/"/g,'style':'sh_string'},{'next':16,'regex':/'/g,'style':'sh_string'},{'regex':/(\b(?:class|interface))([ \t]+)([$A-Za-z0-9]+)/g,'style':['sh_keyword','sh_normal','sh_type']},{'regex':/\b(?:abstract|break|case|catch|class|const|continue|debugger|default|delete|do|else|enum|export|extends|false|final|finally|for|function|goto|if|implements|in|instanceof|interface|native|new|null|private|protected|prototype|public|return|static|super|switch|synchronized|throw|throws|this|transient|true|try|typeof|var|volatile|while|with)\b/g,'style':'sh_keyword'},{'regex':/\b(?:int|byte|boolean|char|long|float|double|short|void)\b/g,'style':'sh_type'},{'regex':/~|!|%|\^|\*|\(|\)|-|\+|=|\[|\]|\\|:|;|,|\.|\/|\?|&|<|>|\|/g,'style':'sh_symbol'},{'regex':/\{|\}/g,'style':'sh_cbracket'},{'regex':/(?:[A-Za-z]|_)[A-Za-z0-9_]*[ \t]*(?=\()/g,'style':'sh_function'}],[{'exit':true,'regex':/$/g},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'next':2,'regex':/<!DOCTYPE/g,'state':1,'style':'sh_preproc'},{'next':4,'regex':/<!--/g,'style':'sh_comment'},{'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'style':'sh_keyword'},{'next':5,'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'state':1,'style':'sh_keyword'},{'regex':/&(?:[A-Za-z0-9]+);/g,'style':'sh_preproc'},{'regex':/@[A-Za-z]+/g,'style':'sh_type'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}],[{'exit':true,'regex':/>/g,'style':'sh_preproc'},{'next':3,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/-->/g,'style':'sh_comment'},{'next':4,'regex':/<!--/g,'style':'sh_comment'}],[{'exit':true,'regex':/(?:\/)?>/g,'style':'sh_keyword'},{'regex':/[^=" \t>]+/g,'style':'sh_type'},{'regex':/=/g,'style':'sh_symbol'},{'next':6,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/\*\//g,'style':'sh_comment'},{'next':8,'regex':/\/\*\*/g,'style':'sh_comment'},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'next':9,'regex':/<!DOCTYPE/g,'state':1,'style':'sh_preproc'},{'next':11,'regex':/<!--/g,'style':'sh_comment'},{'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*(?:\/)?>/g,'style':'sh_keyword'},{'next':12,'regex':/<(?:\/)?[A-Za-z][A-Za-z0-9]*/g,'state':1,'style':'sh_keyword'},{'regex':/&(?:[A-Za-z0-9]+);/g,'style':'sh_preproc'},{'regex':/@[A-Za-z]+/g,'style':'sh_type'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}],[{'exit':true,'regex':/>/g,'style':'sh_preproc'},{'next':10,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/-->/g,'style':'sh_comment'},{'next':11,'regex':/<!--/g,'style':'sh_comment'}],[{'exit':true,'regex':/(?:\/)?>/g,'style':'sh_keyword'},{'regex':/[^=" \t>]+/g,'style':'sh_type'},{'regex':/=/g,'style':'sh_symbol'},{'next':13,'regex':/"/g,'style':'sh_string'}],[{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/\*\//g,'style':'sh_comment'},{'next':14,'regex':/\/\*/g,'style':'sh_comment'},{'regex':/(?:<?)[A-Za-z0-9_\.\/\-_]+@[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:<?)[A-Za-z0-9_]+:\/\/[A-Za-z0-9_\.\/\-_]+(?:>?)/g,'style':'sh_url'},{'regex':/(?:TODO|FIXME)(?:[:]?)/g,'style':'sh_todo'}],[{'exit':true,'regex':/"/g,'style':'sh_string'},{'regex':/\\./g,'style':'sh_specialchar'}],[{'exit':true,'regex':/'/g,'style':'sh_string'},{'regex':/\\./g,'style':'sh_specialchar'}]];

if(!this.sh_languages){this.sh_languages={};}
sh_languages['ruby']=[[{'regex':/\b(?:require)\b/g,'style':'sh_preproc'},{'next':1,'regex':/#/g,'style':'sh_comment'},{'regex':/\b[+-]?(?:(?:0x[A-Fa-f0-9]+)|(?:(?:[\d]*\.)?[\d]+(?:[eE][+-]?[\d]+)?))u?(?:(?:int(?:8|16|32|64))|L)?\b/g,'style':'sh_number'},{'next':2,'regex':/"/g,'style':'sh_string'},{'next':3,'regex':/'/g,'style':'sh_string'},{'next':4,'regex':/</g,'style':'sh_string'},{'regex':/\/[^\n]*\//g,'style':'sh_regexp'},{'regex':/(%r)(\{(?:\\\}|#\{[A-Za-z0-9]+\}|[^}])*\})/g,'style':['sh_symbol','sh_regexp']},{'regex':/\b(?:alias|begin|BEGIN|break|case|defined|do|else|elsif|end|END|ensure|for|if|in|include|loop|next|raise|redo|rescue|retry|return|super|then|undef|unless|until|when|while|yield|false|nil|self|true|__FILE__|__LINE__|and|not|or|def|class|module|catch|fail|load|throw)\b/g,'style':'sh_keyword'},{'next':5,'regex':/(?:^\=begin)/g,'style':'sh_comment'},{'regex':/(?:\$[#]?|@@|@)(?:[A-Za-z0-9_]+|'|\"|\/)/g,'style':'sh_type'},{'regex':/[A-Za-z0-9]+(?:\?|!)/g,'style':'sh_normal'},{'regex':/~|!|%|\^|\*|\(|\)|-|\+|=|\[|\]|\\|:|;|,|\.|\/|\?|&|<|>|\|/g,'style':'sh_symbol'},{'regex':/(#)(\{)/g,'style':['sh_symbol','sh_cbracket']},{'regex':/\{|\}/g,'style':'sh_cbracket'}],[{'exit':true,'regex':/$/g}],[{'exit':true,'regex':/$/g},{'regex':/\\(?:\\|")/g},{'exit':true,'regex':/"/g,'style':'sh_string'}],[{'exit':true,'regex':/$/g},{'regex':/\\(?:\\|')/g},{'exit':true,'regex':/'/g,'style':'sh_string'}],[{'exit':true,'regex':/$/g},{'exit':true,'regex':/>/g,'style':'sh_string'}],[{'exit':true,'regex':/^(?:\=end)/g,'style':'sh_comment'}]];

