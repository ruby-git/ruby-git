-- pandoc-man-filter.lua
--
-- Transformations applied when converting groff man pages to GFM:
--
-- 1. Demote headings by three levels (H1→H4, H2→H5) so that man-page section
--    headings (NAME, SYNOPSIS, OPTIONS, …) nest correctly under the per-page
--    ### heading added by generate_git_reference.
--
-- 2. Convert BlockQuote elements to one of:
--    a. BulletList  — when consecutive BlockQuotes start with Para ["·"] (U+00B7),
--                     which is how groff represents bullet list items.
--    b. OrderedList — when consecutive BlockQuotes start with Para ["1."], Para ["2."],
--                     etc., which is how groff represents numbered list items.
--    c. CodeBlock   — when the BlockQuote's first child is already a CodeBlock
--                     (pandoc wraps some literal code examples in a BlockQuote).
--    d. GFM blockquote (unchanged) — all other BlockQuotes, which are prose
--                     option descriptions. GFM blockquotes ("> text") render
--                     inline Markdown correctly, so bold and links work inside
--                     them. 4-space-indented code blocks do NOT render links.
--
--    All cases are handled in a single Blocks() pass so that consecutive
--    bullet/numbered items can be collected into one list node.

-- U+00B7 MIDDLE DOT: groff uses this as a bullet character in man pages.
local BULLET = "\xC2\xB7"

local function blockquote_first_para_text(block)
  if block.t ~= "BlockQuote" then return nil end
  if #block.content < 1 then return nil end
  local first = block.content[1]
  if first.t ~= "Para" then return nil end
  return pandoc.utils.stringify(first)
end

local function is_bullet_blockquote(block)
  return blockquote_first_para_text(block) == BULLET
end

local function is_numbered_blockquote(block)
  local text = blockquote_first_para_text(block)
  return text ~= nil and text:match("^%d+%.$") ~= nil
end

-- Extract the item content (everything after the first Para) from a BlockQuote.
local function blockquote_item_content(block)
  local item = {}
  for j = 2, #block.content do
    table.insert(item, block.content[j])
  end
  if #item == 0 then item = { pandoc.Plain({}) } end
  return item
end

-- Blocks() processes each sibling list, letting us merge consecutive items.
function Blocks(blocks)
  local result = {}
  local i = 1
  while i <= #blocks do
    local block = blocks[i]
    if is_bullet_blockquote(block) then
      local items = {}
      while i <= #blocks and is_bullet_blockquote(blocks[i]) do
        table.insert(items, blockquote_item_content(blocks[i]))
        i = i + 1
      end
      table.insert(result, pandoc.BulletList(items))
    elseif is_numbered_blockquote(block) then
      local items = {}
      while i <= #blocks and is_numbered_blockquote(blocks[i]) do
        table.insert(items, blockquote_item_content(blocks[i]))
        i = i + 1
      end
      table.insert(result, pandoc.OrderedList(items))
    elseif block.t == "BlockQuote" then
      if #block.content > 0 and block.content[1].t == "CodeBlock" then
        -- Code example wrapped in a redundant BlockQuote: unwrap to CodeBlock.
        table.insert(result, block.content[1])
      else
        -- Prose description (e.g. option bodies): leave as a GFM blockquote
        -- ("> text"). Markdown formatting works inside blockquotes, so bold
        -- and cross-reference links will render correctly.
        table.insert(result, block)
      end
      i = i + 1
    else
      table.insert(result, block)
      i = i + 1
    end
  end
  return result
end

function Header(el)
  el.level = el.level + 3
  return el
end
