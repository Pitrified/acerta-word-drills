# Project Documentation

The tooling and conventions of this repo come from [fala-language-tutor](https://github.com/Pitrified/fala-language-tutor), a sibling Flutter app.

## Reading order

1. [project-structure.md](project-structure.md) - WHERE code lives
2. [coding-standards.md](coding-standards.md) - HOW code is written
3. [git-workflow.md](git-workflow.md) - HOW changes are committed and merged
4. [getting-started.md](getting-started.md) - Get it running locally
5. [content.md](content.md) - WHAT words the app ships and how they are loaded
6. [build-and-release.md](build-and-release.md) - HOW an APK is built and signed

## Index

### Project and process

- [project-structure.md](project-structure.md)
- [coding-standards.md](coding-standards.md)
- [git-workflow.md](git-workflow.md)
- [getting-started.md](getting-started.md)
- [content.md](content.md) - the word asset, its export and its loading

### AI workflow

- [ai-development-playbook.md](https://github.com/Pitrified/flutter-setup-project/blob/main/docs/ai-development-playbook.md)

### Build and release

- [build-and-release.md](build-and-release.md) - build, sign, split APKs
- [privacy-policy.md](privacy-policy.md) - what the app collects

## Mental model

| Doc | Question it answers |
|-----|---------------------|
| Project structure | Where does code live? |
| Coding standards | How do we write code? |
| Git workflow | How do changes land? |
| Getting started | How do I run it? |
| Content | Which words ship, and how do they get updated? |
| Build and release | How do we ship? |
| Privacy policy | What happens to the user's data? |

## Ground rules

- Docs describe what is; the history is in [plans/](../plans/)
- Docs link to each other - never duplicate content
- Update the docs in the same change as the code they describe
- If something is unclear, ask the user, then update the docs before implementing
