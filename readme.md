# The pewpewthespells.com Website Stack

## Background

This repos contains the entirity of the technology stack that runs [pewpewthespells.com](https://pewpewthespells.com). It consists of primarily static content that is processed by `rite` using a set of rules to prepare it for being viewed on the web. This content is then served by `ritual`, which is a web-server powered by the [Jester](https://github.com/dom96/jester) web framework.

## Building

### 0. Prerequisites
To run this stack yourself, you will need to have [Nim](https://nim-lang.org) installed. On OS X you can acquire this through homebrew:

```shell
$ brew install nim
```

on Ubuntu and other linux platforms you may need to install from source, you can find the instructions for that on their website [here](https://nim-lang.org/download.html).

### 1. Building the Tools

All of the code is written in Nim and uses [Nimble](https://github.com/nim-lang/nimble) (the Nim package manager) to build both the content generator and the web framework that is used to serve content. To build the tools, run the following command:

```shell
$ nimble build
```

This will generate binaries for both `rite` and `ritual`.

### 2. Preparing Content

To prepare content for the web, you will need to create a `sitemap.yml` file that describes the following:

```yaml
export_dir: "relative path from the sitemap file that is where the processed content should be copied to"

rules:
   - { import_as: "input file extension", export_as: "output file extension", cmd: "command to run that will process the input and turn it into the output"" }
   ...

files:
  - { name: "relative file path", export_as: "semi-colon separate string of file extensions that you want to be exported to for the web" }
  ...
```

There are a couple of special strings that can be used to substitute into the `rule.cmd` string:

* `%input%`, this is the path to the input file
* `%output%`, this is the path to the output file
* `%output_dir%`, this is the path to the directory that the output should use
* `%self%`, this is the path to the directory that the sitemap file is in

### 3. Processing Content

Once the `sitemap.yml` file is configured with all of the content for the site, it will need to be processed by `rite`. To do this, run `./rite` and pass it a single argument of the path to the `sitemap.yml` file. When processing content `rite` will output what files it is currently generating. If `rite` encounters an error, then it will print out an error message and quit immediately.

### 4. Serving Content

All content is served by `ritual`. To start serving the website content, run `./ritual` with a single argument of the same `sitemap.yml` path you passed when running `rite`. This will use the sitemap file to determine the location of the exported content to serve and serve it statically.

## Additional Tools

While all content can be served directly by `ritual` using the Jester framework, it doesn't offer many of the common features of web-servers (such as logging and certificates). To do these things, I am running `nginx` as a reverse proxy to the `ritual` Jester application. This is to enhance the security and provice a more common interface for things like LetsEncrypt.

I have included a copy of my `nginx` configuration file for reference to demonstrate how this works.



