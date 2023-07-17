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
    
    ------------------------------------------- [ 2023-03-25 21:17:40.251332 -0700 ]

    -=> Testing section: basic commands <=-
        ✅ Login successful for test_user
        ✅ who: top_line_matches
        ✅ who: first_row_of_table_matches
        ✅ spodlist: bottom_line_contains
        ✅ Logout successful for test_user

    -=> Testing section: other tests <=-
        ✅ Login successful for test_user
        ❌ example_test: custom failed test output
        ✅ example_test: custom passed test output
        ✅ Logout successful for test_user

    -=> Testing section: admin tests <=-
        ✅ Login successful for admin_test_user
        ✅ backup_operation: process complete 
        ✅ Logout successful for admin_test_user

    -------------- [  18 pass   0 fail   0 err   ] - [ completed in 0009.0266 secs ]

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

🔴 **Don't use PG+ Test with your production talker.** 

PG+ Test is designed to find things that are broken. It can act as an administrator on the talker, create and delete talker data, and otherwise engage in mischief and jiggery-pokery, so you should only ever point it at a test talker.

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

Profiles let you test various types of talker functionality. At a minimum, PG+ Test expects there to be a standard user profile and an admin profile. That should be sufficient for all of the pre-fab tests. Add other profiles as needed for the fancy new tests you write. 

### SSH Access

For tests that look at the filesystem, you can configure SSH access. If you don't feel like doing that, make sure you comment out any tests in `test-plan.yaml` that include `ssh: true`. 

Currently, only the [PEM file strategy](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html) for SSH credential storage is implemented in PG+ Test. Unlike test characters on an ephemeral test talker running on telnet, we should probably expect SSH credentials to be treated with confidentiality, hence PG+ Test does not support a username/password strategy for SSH. PRs are welcome for other secure strategies besides PEM.

## Building the Test Plan

Finally, the fun part! The test plan in `config/test-plan.yaml` is what it says — the plan (in order) of all the tests you want to run. You can add, change, remove, comment out, etc. Hopefully this is all fairly intuitive, but here some hints:

1. No-code-required `basic_commands` section lets you exercise any of a suite of standard tests against any standard talker command (see the next section). 
2. Add your custom tests to the `other_tests` section, which will be executed with the standard user profile.
3. Add tests that require admin privs to the `admin_tests` section.

## Adding Basic Command Tests and Stubs

Basic command tests (in the `basic_commands` section of the test plan) don't require any new code to configure. You can just plop the command you want to run in there, state which tests you want to run against it (for example, the `all_lines_match` test which — surprise — validates that every line in the stub matches), and add a stub for the expected output in `data/stubs.yaml`. Let's look at some examples:

### Example: add a test for a new basic command

Say you've added a new command to your talker called `cocktail <drink>` that provides the recipe for a given drink and you want to add a test for it (side note: I totally made up the idea for this command while I was writing this README, then decided it was a great idea, so when you're done reading this, check out [PG+ Cocktail Recipe](https://github.com/jmodjeska/pgplus-cocktail)!).

1. **Get a stub.** Go to your talker and capture some example output. Maybe you're in the mood for an old fashioned, so you capture the output for `cocktail old fashioned`, which looks like this:

    ````
    ==================== Cocktail recipe for: Old Fashioned ===================

    Old Fashioned: 
    A pre-dinner drink with a boozy taste.

    Ingredients:

    - Rye Whiskey: 6 cl
    - Simple syrup: 1 cl
    - Angostura bitters: 2 dashes

    Preparation: Stirred.

    ===========================================================================
    ````
    
 2. **Add the stub to `data/stubs.yaml`.** The order of stubs in the stubs file doesn't matter, but I recommend dropping it in the top section, which is `# Command stubs (stub name exactly matches the command issued on the talker)` to keep things easy to reason about. The stub will look like this, with a YAML block string directive at the top and four spaces of indentation:

    ````
    cocktail old fashioned: |

        ==================== Cocktail recipe for: Old Fashioned ===================

        Old Fashioned: 
        A pre-dinner drink with a boozy taste.

        Ingredients:

        - Rye Whiskey: 6 cl
        - Simple syrup: 1 cl
        - Angostura bitters: 2 dashes

        Preparation: Stirred.

        ===========================================================================
    ````
    
3. **Update the test plan.** In the `basic_commands` section of `config/test-plan.yaml`, add a new section for your `cocktail` command. Tests in this section are run in order, so drop it wherever in the plan you want it. Since the output of `cocktail` is not variable, the easiest test to run is `all_lines_match`. Note that I called this test `cocktail_old_fashioned` to make it easy to reason about, but for basic commands, you can name the test whatever you want.
 
    ````
    - cocktail_old_fashioned:
        cmd: 'cocktail old fashioned'
        tests_to_run:
            all_lines_match:
    ````

4. That's it! Save your files and you're ready to execute your new test as part of your test plan. You can run PG+ Test with the `-b` flag to only execute the `basic_commands` section of the plan. This section should run pretty quickly.

For commands with variable output, consider using some of the other basic command tests such as `bottom_line_contains`.

### Example: add a test for a new social

Socials are even easier to add, though note that PG+ Test only checks Used Room Message output because it doesn't (yet) support testing of character interactions. Look at `apol testing` and `zzz` in the example test plan to see how to include socials that, respectively, do and don't take an argument.

## Custom Tests and Dev Mode

**TODO**: Expand this section. For now, some hints:

1. Add new tests to `lib/tests.rb`.
1. Use the `-d` flag to only exercise tests in the `development` section of the test plan. This makes development easier because you don't have to wait for the other tests to run. When you're finished developing, move your test to a different section (`other_tests` or `admin_tests` depending on what kind of access it needs).
2. In another terminal window, run `tail -f data/out.log` to watch tests execute in real-time. This makes debugging easier, as PG+ Test will drop some debug messages in the output log.
3. Unlike basic command tests, stubs for custom tests expect the stub name to match the name of the test method. So, if you define a new test method like this: `def custom_test_name(h)`, and it needs a stub, call the stub `custom_test_name`. 
4. `h` is the Telnet test harness. You will want to pass that to most new test methods unless they are only doing filesystem actions.
5. `ssh` is the SSH connection. Pass it to any methods that require SSH access.
6. Always return a properly-formatted array containing your test results. It should look like this: `return [:results, passfail, expected, actual]`, where `:results` is a static symbol that tells the Reporter library what kind of message it's getting (so don't change it), `passfail` is a boolean that summarizes whether the test passed or not, and `expected` and `actual` are whatever data type and content you desire - ideally something that briefly describes what you wanted to happen (e.g., "all lines match"), and what did happen (e.g., "bourbon != gin"). I recommend adding only the failed bits into a hash and using `output_hash(hash_of_failed_bits)` to format it nicely for output. It will look something like this:

    ````
    ❌ validate_cocktail_menu
       Expected: all spirits match stub data
       Received: bourbon => gin
    ````

## Roadmap

Who knows how much time I'll have for this project, but some nice-to-have future features might include:

1. **Fuzzy matching for commands with variable output.** For example, to validate output from the `idle` command requires that the stub allows for variable idle times. 
1. **Multi-player connections.** Currently, PG+ Test only operates as one user at a time. This limits our ability to test player-to-player interactions, so a nice feature for the future will be simultaneous multi-player connections.
2. **Spin up and test an out-of-the-box PG+ install.** Maybe with Docker or something?
3. **Base library for standard PG+.** I built this project for [UberWorld](https://uberworld.org), which is a significantly customized branch of the PG+ codebase. So far, all of the examples it ships with are for UberWorld and may require adaptation to run with standard PG+. I'll try to make it more readily-functional out of the box if anyone else ever uses it :)
4. **Talker + test deployment pipeline**. I mean, why not go totally bananas, right?

## You might also like
* [ChatGPT Bot for PG+](https://github.com/jmodjeska/pgplus-aiyu)
* [Short Link Generator for PG+ Talkers](https://github.com/jmodjeska/pgplus_shortlink)
* [PG+ Cocktail Recipe](https://github.com/jmodjeska/pgplus-cocktail)
* [PG+ Threading](https://github.com/jmodjeska/pgplus-threads)

