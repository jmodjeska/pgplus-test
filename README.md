# PG+ Test
**PG+ Test is a standalone, external, end-to-end testing harness and test development framework for [Playground+ talkers](https://github.com/talkersource/playground-plus).**

PG+ Test is useful out-of-the-box as well as extensible; it . . .

* Comes with lots of ready-to-run examples
* Makes it easy to add your own custom tests
* Lets you customize and add comparison stub data by copying and pasting from your talker's output

PG+ Test is private; it . . .

* Installs and runs as a standalone application entirely within your local \*nix/Mac system
* Acts as a user on your talker's remote or local test instance to exercise talker functionality
* Does not communicate with any third-party system
* Does not interact directly with talker source code


## Synopsis

    $ ruby pgplus-test.rb
    
    --------------------------------------------------------------------------------

    -=> Testing section: basic commands <=-
        ✅ Login successful for test_user
        ✅ who: top_line_matches
        ✅ who: first_row_of_table_matches
        ✅ spodlist: bottom_line_contains
        ✅ Logout successful for test_user
    -=> Section complete: basic commands <=-

    -=> Testing section: other tests <=-
        ✅ Login successful for test_user
        ❌ example_test: custom failed test output
        ✅ example_test: custom passed test output
        ✅ Logout successful for test_user
    -=> Section complete: other tests <=-

    -=> Testing section: admin tests <=-
        ✅ Login successful for admin_test_user
        ✅ backup_operation: process complete 
        ✅ Logout successful for admin_test_user
    -=> Section complete: admin tests <=-

## Usage

    ruby pgplus-test.rb -h

    Synopsis: ruby pgplus-test.rb
      -d, --dev-mode       Only run tests specified in `development` section
      -b, --basic          Only run test in the `basic_commands` section
      -p, --profile=<s>    Specify a test profile for non-admin tests) (default: test)
      -h, --help           Show this message

## Installation

Verify your installation of Ruby is a reasonably current vintage (this project was developed and tested on **Ruby >=3.0**)
    
    ruby -v

Clone this repo

    git clone https://github.com/jmodjeska/pgplus-test/

Install dependencies

    bundle install

## Really Important Configuration

### Setup a Test Talker

**Don't use PG+ Test with your production talker.** PG+ Test is designed to find things that are broken. It can act as an administrator on the talker, create and delete talker data, and otherwise engage in mischief and jiggery-pokery, so you should only ever point it at a test talker.

### Prompt

Configuring the prompt is essential for PG+ Test to know when a talker command has completed. Since the PG+ prompt is configurable by talker and by individual user, you'll need to customize this for each user profile or else attempted commands to your talker will time out.

The example PG+ Test config file defines the prompt as `PG+>`, which is the [default prompt](https://github.com/talkersource/playground-plus/blob/master/soft/pdefaults.msg#L13) that ships with PG+ source code. This is expressed in the config using regex syntax as `PG\+\>`.

        test:
        ip: '0.0.0.0'
        port: '2020'
        username: 'test-user-name'
        password: '123-fake-password'
        prompt: 'PG\+\>'

### Profiles

Profiles let you test various types of talker functionality. At a minimum, PG+ Test expects there to be a standard user profile and an admin profile. That should be sufficient for all of the pre-fab tests. Add other profiles as needed for the fancy new tests you want write. 

### SSH Access

For the test that look at the filesystem, you can configure SSH access. If you don't feel like doing that, make sure you comment out any tests in `test-plan.yaml` that include `ssh: true`. 

Currently, only the [PEM file strategy](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html) for SSH credential storage is implemented in PG+ Test. Unlike test characters on an ephemeral test talker running on telnet, we should probably expect SSH credentials to be treated with confidentiality, hence PG+ Test does not support a username/password strategy for SSH. PRs are welcome for other secure strategies.

## Building the Test Plan

Finally, the fun part! The test plan in `config/test-plan.yaml` describes all the tests you want to run. You can add, change, remove, comment out, etc. Hopefully this is all fairly intuitive, but here are a hints:

1. No-code-required `basic_commands` section lets you exercise any of a suite of standard tests against any standard talker command (see the next section). 
2. Add your custom tests to the `other_tests` section, which will be executed with the standard user profile.
3. Add tests that require admin privs to the `admin_tests` section.

## Adding Basic Tests and Stubs

TODO ...

Most of them expect a corresponding stub in `data/stubs.yaml` with the command output. You only need one stub regardless of how many `tests_to_run` you apply to a command. 

## Custom Tests and Dev Mode

TODO ...

## Roadmap

Who knows how much time I'll have for this project, but some nice-to-have future features might include:

1. **Multi-player connections.** Currently, PG+ Test only operates as one user at a time. This limits our ability to test player-to-player interactions, so a nice feature for the future will be simultaneous multi-player connections.
2. **Spin up and test an out-of-the-box PG+ install.** Maybe with Docker or something?

## You might also like
[Short Link Generator for PG+ Talkers](https://github.com/jmodjeska/pgplus_shortlink)
