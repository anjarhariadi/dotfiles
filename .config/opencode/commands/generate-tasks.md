---
description: "Create list of plan from Low Level Document (LLD)"
---

# Plan all tasks from lld

## LLD

Read lld file: `$ARGUMENTS`

## Mission

i need you to create all the task needed into .docs/tasks/tasks_tahap_3.md. Here's the rule:
- Separate into section regarding the context of work, just like Epic in jira (ex: ## Product, ## Booking)
- List the user story in bahasa indonesia, this is not the task but the whole structure of work to be done (ex: - Sebagai calon jamaah, saya ingin melihat daftar produk yang tersedia)
- List the actual tasks under user story, use [BE], or [FE] prefix for clarition of who needs to working on the task, each task should have story point using fibbonaci with value must not be greater than 13, any number greater than 13 means you need to breakdown the task into chunk of smaller number (example from story above:
- [BE] Implement public get product endpoint (3)
- [FE] Slicing public product page (2)
- [FE] Integrate to public get product API endpoint (3)
) 
- Minimize writing underwater tasks, such as blocking tasks, architectural stuff not necesarilly written as it's surely need to do as implement task.
- Keep align on user perspective when writing user stories, not engineering team, engineering stuffs not necesarilly be written.
