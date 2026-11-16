# Vendored theme

`hugo-book/` is [Hugo Book](https://github.com/alex-shpak/hugo-book), MIT
licensed, copied unmodified from tag `v13`, commit
`cec082b8dd9b31d0c52b2de95d86ced9909cc7ec`, without `exampleSite/`,
`images/` and `.github/`.

Do not edit it. Overrides live in the site's `layouts/` (see the README):

- `layouts/baseof.html` and `layouts/_partials/docs/html-head.html` replace
  `.Site.LanguageCode` and `.Language.LanguageDirection`, deprecated in Hugo
  0.158, and pass `silenceDeprecations: [import]` to Dart Sass for the
  theme's `@import` rules;
- `layouts/_partials/docs/brand.html` replaces `.Sites`, deprecated in Hugo
  0.156;
- `layouts/_partials/docs/html-head-title.html` titles the home page.

To update: copy the new tag the same way, record it here, re-apply or drop
the overrides, and build with `--panicOnWarning`.
