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

## Installation

Verify your installation of Ruby is a reasonably current vintage (this project was developed and tested on **Ruby >=3.0**)
    
    ruby -v

Clone this repo

    git clone https://github.com/jmodjeska/pgplus-test/

Install dependencies

    bundle install

## Configuration

  * Prompt (IMPORTANT)
  * Profiles

## Building the Test Plan

## Adding tests and stubs

## You might also like
[Short Link Generator for PG+ Talkers](https://github.com/jmodjeska/pgplus_shortlink)
