# Reference Apps

This repository contains rendered templates from [software-templates](https://github.com/coreeng/software-templates) repository.
Every time any template is changed `render-templates.yaml` workflow is triggered.
This workflow will render all templates, commit the changes and run the whole P2P for updated templates.

Hence, changes to applications are happening automatically
and any application update made directly to this repository will be overwritten.
If you want to update an application, please make a PR
to [software-templates](https://github.com/coreeng/software-templates) repository.

# Quick Start
You can fork this repository to your organization and use it as a starting point for your own applications.

The only thing you need to do to make P2P work properly for your organization is to run:
```bash
corectl p2p env sync <your-repository> <your-tenant>
```
This will use configuration from your environments to prepare your repository for P2P.

Read more about `corectl` [here](https://github.com/coreeng/corectl).

# Configured workflows

## Template rendering
These are used to render templates. Should be deleted after forking.
- `render-template.yaml` - fetches all the templates from [software-templates](https://github.com/coreeng/software-templates) repo, 
    renders it and collect ids of changed templates. For each changed template, it calls `p2p.yaml`. 
- `p2p.yaml` - runs the whole P2P in one go.

## P2P workflows for forked 
These workflows are supposed to be used after forking the repository.
- `fast-feedback.yaml`, `extended-test.yaml`, `prod.yaml` - run certain P2P stage for a given application.
- `matrix-fast-feedback.yaml`, `matrix-extended-test.yaml`, `prod.yaml` - generate matrix of applications to be handled for a certain P2P stage.
    `matrix-extended-test.yaml` and `prod.yaml` are triggered on schedule or manual call.
    `matrix-fast-feedback.yaml` is triggered on push to main to on PRs. `matrix-fast-feedback.yaml` only runs for applications that have changed.