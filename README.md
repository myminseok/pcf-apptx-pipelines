# PCF App Transformation Pipelines

The goal of this project is to provide a set of reusable Concourse tasks that can be piped together to create a CI/CD pipeline in your project. A subset of these tasks were taken from straight from [Spring Cloud Pipelines](https://github.com/spring-cloud/spring-cloud-pipelines/tree/master/concourse) with some small enhancements that you can see from the commit history. For examples of how to use these tasks, have a look at [github-webhook](https://github.com/malston/github-webhook) and [sample-spring-cloud-svc](https://github.com/malston/sample-spring-cloud-svc). The `github-webhook` project is a fork from the Spring Cloud Pipelines demo that uses these tasks instead of the Spring Cloud Pipelines ones. The `sample-spring-cloud-svc` project uses these tasks as well as some supplemental ones that demonstrate how to use the gitflow branching strategy with these tasks. Some polishing still needs to be done to the supplemental tasks which is why they haven't made their way into this repo yet.

## Examples

There are two examples that you can look at for how to use these tasks in a
Concourse pipeline.

1. [Github-webhook](https://github.com/malston/github-webhook)
2. [Simple-message-service](https://github.com/malston/sample-spring-cloud-svc)

More docs to come...
