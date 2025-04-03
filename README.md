# Development

Download the project, either via `git`
```
git clone https://github.com/benthillerkus/bretagne.git
cd bretagne
code .
```
or as a [`.zip` from GitHub]((https://github.com/benthillerkus/bretagne/archive/refs/heads/main.zip)).

Open the Godot editor and in the projects list select **Import**

![[The Godot Editor projects list]](docs/projects%20list.png)

and then import either your project folder or the zip you downloaded.

## Engine

The project was made in [Godot 4.4](https://godotengine.org/download/archive/4.4-stable/).

## LFS

This project uses [`git-lfs`](https://git-lfs.com/) for everything that isn't plain text source code or configuration.

Please contact me directly if you want access to those binary / media assets. Their licensing is specified in [LICENSE](LICENSE), but due to technical constraints I cannot grant access to just anyone.

If you have write access to this repository, you need a [GitHub personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#creating-a-fine-grained-personal-access-token) with atleast the `org:read` scope to access the LFS.

Make sure you have `git-lfs` installed.

```
git lfs install
```

You can try to increase local performance by changing some git config settings[^1]:
```
# Increase the number of worker threads
git config --global lfs.concurrenttransfers 64

# Use a global LFS cache to make re-cloning faster
git config --global lfs.storage ~/.cache/lfs
```

[^1]: As per https://github.com/jasonwhite/rudolfs?tab=readme-ov-file#client-configuration

## VS Code

Install the [Godot Tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) extension for smart autocompletion.

You can point it to your editor by creating a `.vscode/settings.json` with the path to your Godot Editor executable.

```json
{
  "godotTools.editorPath.godot4": "c:\\Program Files (x86)\\Steam\\steamapps\\common\\Godot Engine\\godot.windows.opt.tools.64.exe"
}
```

# Acknowledgements

Check out [CREDITS.md](CREDITS.md) for a list of all used resources and the licenses of included software libraries.
