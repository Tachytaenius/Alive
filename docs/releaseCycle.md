# Release Cycle

## Versioning

The version number is incremented in code as the next commit after every release.
So when working on the game, the version number in code is the version number of the next version to be released.
It is to be stored in save files, preventing saves from being opened by previous versions of the game and potentially requiring conversion when opened by later versions of the game.
It is also to be stored in input-based replays, requiring the running version of the game to be the same as the one that recorded the replay.

## Changelogging

Changes between releases are added to the changelog under the future section.
Every release, the future section is moved to a section labelled with the current version in code.
