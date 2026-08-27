## To publish a release

1. Bump the version using the appropriate make target:
2. [Create](https://github.com/artginzburg/MiddleClick/releases/new) a new _draft_ release, setting its tag and title to the new `MARKETING_VERSION`. Click "Save draft", don't publish.
3. Run the ["Build, Sign and Upload MiddleClick"](https://github.com/artginzburg/MiddleClick/actions/workflows/build-to-release.yml) workflow.
   make bump-patch   # bug fixes only        → x.y.Z
   make bump-minor   # new features           → x.Y.0
   make bump-major   # breaking changes       → X.0.0
   ```

   This updates `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the Xcode project and stamps `docs/CHANGELOG.md` with the new version and today's date, leaving a fresh `[Unreleased]` section at the top for future work.

   > **Semantic versioning rule of thumb**
   > - *patch* — something that was broken now works; no new behaviour
   > - *minor* — new opt-in behaviour; existing workflows unchanged
   > - *major* — existing workflows broken or configuration incompatible
   >
   > When in doubt between patch and minor, prefer patch for purely internal fixes.
   > Version numbers are always compared as integers, never as strings
   > (the script enforces this: `3.9 → 3.10`, not `3.9 → 3.91`).

2. Commit and push the version bump.

   > If you don't specify a new tag for the draft release, the workflow will destroy the asset uploaded in a previous release. TODO fix that.

- The release should have a MiddleClick.zip asset as a result of the workflow run.

4. Write a description for the release, and publish.

- [The Homebrew cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/m/middleclick.rb) should update automatically in ~3 hours.

  > If that doesn't happen, run:

  ```sh
  brew bump-cask-pr middleclick --version set_MARKETING_VERSION_here
  ```
