WITH matching_dependencies AS (
  SELECT
    dependent_gem.name AS dependent_gem_name,
    dependent_version.number AS dependent_version_number,
    dependent_version.canonical_number AS dependent_version_canonical_number,
    COALESCE(dependent_version.built_at, dependent_version.created_at) AS dependent_version_released_at,
    dependencies.requirements,
    COALESCE(linksets.code, linksets.home) AS url
  FROM rubygems target_gem
  JOIN dependencies
    ON dependencies.rubygem_id = target_gem.id
  JOIN versions dependent_version
    ON dependent_version.id = dependencies.version_id
  JOIN rubygems dependent_gem
    ON dependent_gem.id = dependent_version.rubygem_id
  LEFT JOIN linksets
    ON linksets.rubygem_id = dependent_gem.id
  WHERE target_gem.name = 'git'
    AND (
      dependencies.requirements LIKE '~> 4.%'
      OR dependencies.requirements LIKE '>= %'
    )
),
latest_dependencies AS (
  SELECT DISTINCT ON (dependent_gem_name)
    dependent_gem_name,
    dependent_version_number,
    dependent_version_released_at,
    requirements,
    url
  FROM matching_dependencies
  ORDER BY
    dependent_gem_name,
    dependent_version_canonical_number DESC NULLS LAST,
    dependent_version_number DESC
)
SELECT
  dependent_gem_name,
  dependent_version_number,
  dependent_version_released_at,
  requirements,
  url
FROM latest_dependencies
ORDER BY dependent_version_released_at DESC;