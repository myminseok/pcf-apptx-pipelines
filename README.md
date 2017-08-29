# PCF App Transformation Pipelines

The goal of this project is to provide a set of reusable Concourse tasks that can be piped together to create a CI/CD pipeline in your project. A subset of these tasks were taken from straight from [Spring Cloud Pipelines](https://github.com/spring-cloud/spring-cloud-pipelines/tree/master/concourse) with some small enhancements that you can see from the commit history. For examples of how to use these tasks, have a look at [github-webhook](https://github.com/malston/github-webhook) and [sample-spring-cloud-svc](https://github.com/malston/sample-spring-cloud-svc). The `github-webhook` project is a fork from the Spring Cloud Pipelines demo that uses these tasks instead of the Spring Cloud Pipelines ones. The `sample-spring-cloud-svc` project uses these tasks as well as some supplemental ones that demonstrate how to use the gitflow branching strategy with these tasks. Some polishing still needs to be done to the supplemental tasks which is why they haven't made their way into this repo yet.

## Examples

There are two examples that you can look at for how to use these tasks in a
Concourse pipeline.

1. [Github-webhook](https://github.com/malston/github-webhook)
2. [Simple-message-service](https://github.com/malston/sample-spring-cloud-svc)


## Why not just use Spring Cloud Pipelines

We love [Spring Cloud Pipelines](https://cloud.spring.io/spring-cloud-pipelines/) which is why we kindly took the tasks that Marcin built for reuse here. The trouble with _just_ using Spring Cloud Pipelines is that not every customer is comfortable with it's opinions. For one, it's driven on the pragmatic goal of achieving continuous delivery where every build is a release candidate and if it passes through all the stages of the pipeline it can be deployed to production. The demo projects: github-webhook and github-analytics are concocted to demonstrate the use case where this approach succeeds. And the pipeline itself it tested against these repos which use Spring Cloud for micro-service requirements such as service registration/discovery and consumer-driven tests. These are definitely the principles we want our customers to use, but in reality not every customer can use Spring Cloud Pipelines without making changes to it to fit their release engineering process. So why not just contribute back to Spring Cloud Pipelines to support these release engineering obstacles? We plan to do that, but in cases where the philosophy is too different we will provide support for that here.

Spring Cloud Pipelines supports both Jenkins and Concourse. We have plans to do the same, however, we are looking at taking a slightly different approach to reusability. Spring Cloud Pipelines is handling the reuse of functionality between Concourse and Jenkins by providing a set of common shell scripts that can be used by any pipeline. SCP provides a nice modular way of including those shell scripts into any CI pipeline. The potential problem with this is you may have to make some compromises to your pipeline in order to get value from this approach that may not fit well with the idiomatic nature of the CI system. For example, Concourse has this notion of a [resource](http://concourse.ci/concepts.html#resources) that provides an abstraction that allows you to extend Concourse in ways that hasn't been thought of by the authors. It's similar in respect to Jenkins plugins but with a contract that supports [pipeline-first](http://concourse.ci/concourse-vs.html#jenkins) mentality. It's also where you might choose to leverage reuse if you have a situation where you need to support multiple resources of different types and so you might decide it's better to provide a resource for that functionality rather than a shared shell script.


More to come...
