## To publish a release

1. Bump the `CURRENT_PROJECT_VERSION` and the `MARKETING_VERSION`. Commit, push.
2. [Create](https://github.com/artginzburg/MiddleClick/releases/new) a new _draft_ release, setting its tag and title to the new `MARKETING_VERSION`. Click "Save draft", don't publish.
3. Run the ["Build, Sign and Upload MiddleClick"](https://github.com/artginzburg/MiddleClick/actions/workflows/build-to-release.yml) workflow.

   > If you don't specify a new tag for the draft release, the workflow will destroy the asset uploaded in a previous release. TODO fix that.

- The release should have a MiddleClick.zip asset as a result of the workflow run.

4. Write a description for the release, and publish.

- [The Homebrew cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/m/middleclick.rb) should update automatically in ~3 hours.

  > If that doesn't happen, run:

  ```sh
  brew bump-cask-pr middleclick --version set_MARKETING_VERSION_here
  ```
