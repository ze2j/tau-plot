# Narrative Documentation Guidelines

This document defines how to write the narrative documentation for TauPlot, a GDScript plotting library for Godot. Narrative documentation is everything that teaches or presents the library, as opposed to the class reference, which states the API. Class reference pages follow `class-reference-guidelines.md` instead.

## Scope

Four kinds of file are governed here:

|File|Role|
|---|---|
|Repository README|The GitHub landing page and the Asset Library description.|
|Addon README|Shipped inside the addon, at `addons/tau-plot/README.md` in the released zip.|
|Site landing page|The documentation site entry point.|
|Guides|Step-by-step teaching pages, such as the getting started guide.|

Not every rule applies to every file. Each section below names the files it governs, and the writer checklist is grouped the same way.

The class reference and the narrative documentation share a standard of accuracy and nothing else. Every claim is checked against the source, every snippet runs, and the punctuation prohibitions are identical. Voice, structure, and audience all differ.

## Voice

Applies to every file.

1. Address the reader as "you". A guide teaches and a landing page presents, so the second person is correct here. The class reference forbids it. Keep the two voices apart and never let guide voice reach a reference page.
2. Explain intent before mechanics. Open a section with why the reader would want the thing, then show how to get it.
3. No em dash and no semicolon.
4. No marketing adjectives. State what the library does and let the reader judge whether it is powerful or convenient.
5. Write "for example", not "e.g.".
6. No contractions.

## Snippets

Applies to every file that carries a snippet.

7. Every snippet is complete and runnable. It opens with `extends CenterContainer` and a `_ready()` function, declares every variable it reads, and ends with the `plot_xy()` call.
8. Comments inside a snippet explain why a value was chosen, not what the line does. A comment must never contradict the code beneath it.
9. Indent with tabs, matching `CONTRIBUTING.md` and the codebase.
10. Link a checked-in scene from every snippet a reader might want to run in full.
11. Verify every snippet against the current API before release. A snippet is a promise that the code runs, and a broken one is the most expensive error in narrative documentation, because the reader is copying it.

## Links

Applies to every file that names an API symbol.

12. Link every class, property, and method name in prose into the API reference, using the link formats defined in `class-reference-guidelines.md`. This is what makes a narrative page usable as an entry point into the reference.

## Guides

Applies to guides.

13. A numbered guide section introduces exactly one concept, builds on the section before it, and ends with a screenshot and its caption.
14. A screenshot uses a `/// caption` block with a bold `**Example N**:` label and a one-sentence description of what the image shows.
15. Close a guide with a Next steps section pointing at the reference for everything the guide did not cover.

## The addon README

Applies to the addon README.

16. The addon README ships no images.
17. Every relative link in the addon README resolves inside `addons/tau-plot/`.

## Duplicated content

Applies to the two READMEs and the site landing page.

Some content exists in more than one file by necessity, since a README cannot include a shared fragment. Duplication is accepted, drift is not.

18. The feature list, the opening status sentence, and the Roadmap appear in all three files. A change to one is a change to all three.
19. The quick start snippet appears in all three files. A change to one is a change to all three.

## Writer Checklist

Complete every group that applies to the file you wrote. Skip the groups that do not.

### Every file

- [ ] Every feature claim matches the source tree, including the opening status sentence and the Roadmap.
- [ ] Every symbol named in prose or in a snippet exists in the current API under that exact name.
- [ ] Every default and every behavior described in prose matches the source, not an older page.
- [ ] Every link resolves, and no link points at a file that is empty.
- [ ] The reader is addressed as "you".
- [ ] No em dash, no semicolon, no contraction, no marketing adjective, no "e.g.".
- [ ] Intent comes before mechanics.

### Files with snippets

- [ ] Every snippet parses and runs as written, from a fresh scene.
- [ ] Every variable a snippet reads is declared in that snippet.
- [ ] Every comment agrees with the code below it.
- [ ] Indentation is tabs.
- [ ] Every snippet a reader might run in full links a checked-in scene, and that scene exists and produces the screenshot shown beside it.

### Files that link the API reference

- [ ] Every class, property, and method name in prose links into the API reference.
- [ ] Every link target uses the format defined in `class-reference-guidelines.md`.

### Guides

- [ ] Each numbered section introduces one concept and builds on the previous one.
- [ ] Each section ends with a screenshot, in a `/// caption` block with an `**Example N**:` label.
- [ ] The guide ends with Next steps.

### The two READMEs and the landing page

- [ ] A change to the feature list, the opening status sentence, or the Roadmap was applied to all three files.
- [ ] A change to the quick start was applied to all three files.

### The addon README

- [ ] The file carries no image.
- [ ] Every relative link in it resolves inside `addons/tau-plot/`.