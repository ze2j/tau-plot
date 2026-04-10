# CONTRIBUTING

## AI usage

AI-assisted tools are allowed for this project. However, AI output is only a starting point and is expected to require human judgment, validation, and refinement before being proposed here.

Contributors are not expected to know everything, and contributions from people who are still learning are welcome. What matters is that you understand your contribution well enough to discuss it, improve it, and engage with the review process. If AI was used to help produce a change, you should still be able to explain the code, describe the main design or architectural choices, answer reasonable review questions, and revise the contribution yourself.

For that reason, low-supervision or "vibe coding" workflows are strongly discouraged. A contribution should not be submitted as raw or largely unverified AI output. You are expected to take ownership of the result rather than act as a proxy between reviewers and an AI tool.

Transparency is important. If AI was used in any meaningful way, please say so clearly. This includes, for example, AI-assisted code generation, refactoring, debugging, review or documentation writing. Mentioning it in the pull request description is usually sufficient, and adding context where relevant helps reviewers understand how the contribution was produced.


## Reporting issues

Clear and reproducible issue reports are much easier to investigate and fix. When reporting an issue, please include:

- the **TauPlot version**
- the **Godot version**
- a short description of **what is observed**
- and a clear explanation of **what is expected instead**

Whenever possible, please also attach a **small reproduction project** as a `.zip` file. It should contain **only what is necessary** to reproduce the issue, with unrelated code, assets, and experiments removed. Please **do not include the `.godot/` folder** in the archive. A minimal reproduction project is often the fastest way to investigate an issue.

## Feature requests

Feature requests, ideas, and improvement suggestions are welcome. If you would like to propose a new feature, try to describe **what problem it solves**, **what kind of workflow or use case it improves**, and **why it would be valuable** for TauPlot users.

There is no need to provide a full technical design, but if you already have ideas about a possible implementation, API shape, architecture, or trade-offs, they are very welcome. Even lightweight proposals can be useful as long as the intent is clear.

## Code

Contributions must follow a few basic guidelines to keep the codebase consistent, readable, and maintainable.

- **Indentation and formatting:** use **tabs** for indentation (even if it is not your personal preference, it is the de facto standard for Godot plugins).  
- **Order:** place **public members and methods first** in a class.  
- **Class declaration:** use the `class` keyword to declare new classes. Use `class_name` only if you have a good reason.  
- **Naming:** use **meaningful names**. Abbreviations are acceptable only in very small, local scopes. The larger the scope, the more important it is to be descriptive.  
- **Simplicity:** avoid premature abstractions, follow **KISS** principles.  

- **Understanding your code:** a contributor **must understand their code** fully and be able to explain it. See also [AI usage](#ai-usage).  
- **Tests:** for new features, providing a test or minimal example is strongly encouraged.  
- **Documentation:** class-level documentation is **mandatory**, documenting public methods is encouraged.  
- **Comments:** use comments to explain **why** something is done or to clarify complex logic. Avoid comments that simply repeat what the code does, as the code should be self-explanatory.  
- **Line length:** there is no strict maximum line length, but avoid excessively long lines for readability.  

Please squash your commits to ease the review process and keep the history clean. Your branch may contain multiple commits if they are independent.

## Tests

Tests are visual rather than assertion-based: they render plots directly so regressions and broken features are immediately apparent. Each test is intentionally self-contained and free of abstractions to make isolation and troubleshooting straightforward.

All tests are `@tool` scripts and run inside the Godot editor, except for tests depending on mouse interactions which require running the scene. They can be found in `addons/tau-plot/tests/`.

## Documentation

The documentation is written in markdown and generated in HTML with [`mkdocs`](https://www.mkdocs.org/) and [`Material for MkDocs`](https://squidfunk.github.io/mkdocs-material/).

The following instructions are valid for **Linux** and **macOS** and only need to be done once. If you're not familiar with virtual environments or using a **Windows** platform, you may want to read the [python documentation](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/) first.

### Initial configuration

Create a new virtual environment inside `documentation/`: 
```
python3 -m venv .venv
```

Activate the environment:
```
source .venv/bin/activate
```

Then install `mkdocs` and its dependencies using the `requirements.txt` file:
```
python3 -m pip install -r requirements.txt
```

You are now ready to generate the documentation.

### Generate the documentation

From `documentation/` activate the environment:
```
source .venv/bin/activate
```

Then generate it with:
```
mkdocs build
```

The html files are generated in `documentation/site/`.

### Test the documentation

While the `build` command generates static html files and can be opened with a browser, the links won't work correctly. To navigate seamlessly in the documentation the recommended way is to run a local http server (which `mkdocs` provides).

From `documentation/` activate the environment:
```
source .venv/bin/activate
```

Run the builtin server:
```
mkdocs serve
```

Open the provided url with your browser, which is [http://127.0.0.1:8000/](http://127.0.0.1:8000/) by default.

