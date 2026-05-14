
# OpenCode.ai (opencode)

Installs the OpenCode.ai CLI and dependencies.

## Example Usage

```json
"features": {
    "ghcr.io/chris-w-dev/devcontainers-features/opencode:0": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Specify the version of OpenCode.ai to install. If not provided, the latest version will be used. | string | latest |
| installBun | If true, install the Bun JavaScript runtime as a dependency for OpenCode.ai. | boolean | true |
| copyLocalConfigFolder | If true, copy the contents of ${localEnv:OPENCODE_CONFIG_PATH} to persistent storage during initialization. | boolean | false |
| customInitScript | Custom initialization script for setting up the OpenCode.ai environment. If not provided, a default initialization script will be used. | string | - |

## Configuration

The feature requires defining environment variable `OPENCODE_CONFIG_PATH` to a host path containing the OpenCode.ai configuration folder.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/chris-w-dev/devcontainers-features/blob/main/src/opencode/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
