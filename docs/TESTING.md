# Tests

Common test suites developers might want to run:

* `mix test` — Elixir tests
* `npm run --prefix apps/site/assets mocha && npm run --prefix apps/site/assets jest` — all of the JavaScript tests

IMPORTANT NOTE: As of June 2020, Lechmere is closed for construction and the E line will be terminating at North Station for now. This is the list of files that have been affected (whose changes will need to be reverted at a later time):

- `apps/site/lib/green_line.ex`
- `apps/site/test/green_line_test.exs`
- `apps/site/test/site_web/controllers/schedule/line_test.exs`
- `apps/site/test/site_web/controllers/schedule_controller_test.exs`
- `apps/site/test/site_web/excluded_stops_test.exs`
- `apps/site/test/site_web/views/partial_view_test.exs`
- `apps/stops/test/route_stops_test.exs`

Dotcom runs its test suite automatically using Github Actions, mainly from the [`tests.yml`](../.github/workflows/tests.yml) workflow.

Each test can be run locally by invoking the corresponding NPM script. All the tests are noted below.

## Enabled in Github Actions

### Linting / TypeScript
```sh
 npm run ci:lint:ts
 # This actually runs the following:
 # cd apps/site/assets/ts
 # npx eslint -c .eslintrc.js --ext .ts,.tsx --max-warnings=0 .
 ```
*Runs only if a file with the `.ts` or `.tsx` extension was changed.*

### Linting / JavaScript
```sh
 npm run ci:lint:js
 # cd apps/site/assets
 # git diff --name-only --diff-filter=dx origin/master... | grep js/.*\\.js | xargs npx eslint -c .eslintrc.js
 ```
*Runs only if a file with the `.js` extension was changed.*

### Linting / CSS
```sh
 npm run ci:lint:scss
 # cd apps/site/assets
 # npx stylelint css/**/*.scss --ignore-path .stylelintignore
 ```
*Runs only if a file with the `.scss` extension was changed.*

### Linting / Elixir
```sh
npm run ci:lint:ex
# mix credo diff master -a
```
*Runs only if a file with the `.ex` or `.exs` extension was changed.*

### Unit tests / Elixir
```sh
npm run ci:unit:exunit
# mix test --exclude wallaby --cover
```
*Runs only if a file with the `.ex`, `.exs` or `.eex` extension was changed.*

The CI task should also report test coverage on the PR.

### Unit tests / JavaScript / Mocha
```sh
npm run ci:unit:mocha
# cd apps/site/assets
# npx mocha --require @babel/register --require ts-node/register js/test/**/*.js
```
*Runs only if a file with the `.js` extension was changed.*

### Unit tests / JavaScript & TypeScript / Jest
```sh
npm run ci:unit:jest
# cd apps/site/assets
# npx jest -c ts/jest.config.js
```
*Runs only if a file with the `.js` or `.ts`/`.tsx` extension was changed.*

### Type checks / Elixir
```sh
npm run ci:types:ex
# mix dialyzer --halt-exit-status
```
*Runs only if a file with the `.ex`, `.exs` or `.eex` extension was changed.*

In CI this runs Dialyzer via the `mbta/actions/dialyzer@v1` action. Dialyzer is a static analysis tool which looks at type information. We use it to verify our type specifications and make sure we're calling functions properly.

### Type checks / TypeScript
```sh
npm run ci:types:ts
# cd apps/site/assets/ts
# npx tsc --noEmit --skipLibCheck
```
*Runs only if a file with the `.ts` or `.tsx` extension was changed.*

### Formatting / Elixir
```sh
npm run ci:format:ex
# mix format --check-formatted
```
*Runs only if a file with the `.ex`, `.exs`, or `.eex` extension was changed.*

### Formatting / JavaScript & TypeScript
```sh
npm run ci:format:ts
# cd apps/site/assets
# npx prettier --write "{js,ts}/**/*.{js,ts,tsx}" --list-different
```
*Runs only if a file with the `.js` or `.ts`/`.tsx` extension was changed.*

Frontend code is formatted by Prettier. If using the Prettier plugin for Visual Studio Code, ensure it uses the ignore file `apps/site/assets/.prettierignore`.

## Coming soon

The following tests need additional fixes or implementation. These might be implemented in the `tests.yml` workflow or added to new workflows.

### Integration tests / Elixir ([job](../.github/workflows/tests.yml#L398))
```sh
npm run ci:integration:ex
# mix test --only wallaby
```
*Runs only if a file with the `.ex`, `.exs` or `.eex` extension was changed.*

### Visual regression tests
There is a WIP adding screenshot capturing and visual regression testing using the Percy service. This would replace the use of Backstop (which is at the moment not enabled).

### Performance measurement
There is an early WIP using the Lighthouse CI service for measuring performance metrics. Eventually this will run on a Github Action too.

## ExVCR and ExVCRHelpers

ExVCR is a library that allows mocking out sequences of HTTP requests and
responses, so that tests can run without requesting live data from
third-party services. Since almost everything dotcom does involves requesting
data from the API and/or CMS, this is a valuable capability for our tests to have.

There is a certain amount of boilerplate involved in working with ExVCR. To
automate that boilerplate, we have a library called `ExVCRHelpers`. See
`apps/exvcr_helpers/README.md` for more details on that.

Many tests in the Elixir test suite currently do request live data from the API
and/or CMS. This practice should be avoided for new tests, and ExVCR or
another strategy to mock out live data requests should be used. When tests
using live data break due to changes in that data, that is an opportune time
to convert those tests to use ExVCR.

## CrossBrowserTesting

We use this service to test site changes in Internet Explorer 11 without needing
a local Windows computer or VM.

* [Run a test here!](https://app.crossbrowsertesting.com/livetests/run)
* Sign in using the shared credentials in **Shared-Website-Dev** in LastPass

Only one person can be running a test using this account at a time; be sure to
**Stop** your session once you're done with it.

### Testing local changes

If your changes aren't deployed anywhere, you can use the `cbt_tunnels` tool to
enable CrossBrowserTesting to connect to your local machine.

The easiest way to install this is as a global NPM package:

    npm install -g cbt_tunnels

Then go to https://app.crossbrowsertesting.com/account, copy the **Authkey**,
and start the tunnel using this command:

    cbt_tunnels --username web-tools@mbtace.com --authkey <AUTHKEY>

If the tunnel is working, the "Local Connection" indicator should flip **ON**.
You can now start a test using `local` as the domain, and the connection will be
tunneled to `localhost` on your machine. For example: `http://local:4001/`

## Backstop

We use [BackstopJS](https://github.com/garris/BackstopJS) to test for unexpected
visual changes. Backstop works by keeping a repository of reference images. When
you run a Backstop test, it takes snapshots of pages on your version of the site
and compares them to those reference images. If anything has changed, the test
will fail. This helps us catch unintended changes to the UI (for example a CSS
selector that is broader than expected). Whenever you make a change that affects
the UI, you will need to check and update the Backstop images if necessary.

The tests are run against a live application, built in production mode. To make
sure that the tests work consistently and do not depend on a specific schedule
or realtime vehicle locations, we use [WireMock](http://wiremock.org/) to record
and play back the V3 API responses.

Prerequisites for running the tests:

* Docker
  * `brew cask install docker`
  * Start Docker Desktop from the dock or Applications; this only has to be done
    once, after which it will auto-start on login by default
* Wiremock
  * `brew cask install java --no-quarantine`
    * This option is currently required on OS X 10.15+ due to Gatekeeper
      changes. Ref: https://github.com/Homebrew/homebrew-cask/issues/70798
  * `brew install wiremock-standalone`
* Ensure the [environment variable](ENVIRONMENT.md) `WIREMOCK_PATH` points to
  the Wiremock JAR file; with brew cask this will be something like
  `/usr/local/Cellar/wiremock-standalone/<VERSION>/libexec/wiremock-standalone-<VERSION>.jar`

Once all the above are in place:

* `npm run backstop` — run the tests
* `npm run backstop:record` — run tests with recording of new network requests
* `npm run backstop:approve` — mark the last set of failed diffs as approved

Note: If you are not running on OSX or Windows, you'll need to modify the
`STATIC_HOST=host.docker.internal` in the commands.

## Other helpful test scripts

* [`mbta/link_checker`](https://github.com/mbta/link_checker) - tries to hit all
  the URLs on your server to find invalid links. This automatically runs as part
  of the [`crawler.yml`](../.github/workflows/crawler.yml) workflow.

* `mix run apps/content/bin/validate_fixtures.exs` - compares the attributes in
  our fixture files to production Drupal API endpoints to see if any are
  missing. Note that rather than using this script, it is better to update these
  fixture attributes at the time you are making API changes.
