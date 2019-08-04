#shellcheck shell=sh disable=SC2004

% LIB: "$SHELLSPEC_SPECDIR/fixture/lib"
% BIN: "$SHELLSPEC_SPECDIR/fixture/bin"

Describe "core/dsl.sh"
  Describe "shellspec_example_group()"
    mock() {
      shellspec_output() { echo "$1"; }
      shellspec_yield() { echo 'yield'; }
    }
    It 'calls yield block'
      BeforeRun mock
      When run shellspec_example_group
      The stdout should include 'yield'
    End
  End

  Describe "shellspec_example()"
    mock() {
      shellspec_profile_start() { :; }
      shellspec_profile_end() { :; }
      shellspec_output() { echo "$1"; }
    }
    BeforeRun mock prepare

    Context 'when example is execution target'
      prepare() { shellspec_invoke_example() { echo 'invoke_example'; }; }
      BeforeRun SHELLSPEC_ENABLED=1 SHELLSPEC_FILTER=1 SHELLSPEC_DRYRUN=''

      It 'invokes example'
        When run shellspec_example
        The stdout should include 'invoke_example'
      End
    End

    Context 'when example is aborted'
      prepare() { shellspec_invoke_example() { return 12; }; }
      BeforeRun SHELLSPEC_ENABLED=1 SHELLSPEC_FILTER=1 SHELLSPEC_DRYRUN=''

      It 'outputs abort protocol'
        When run shellspec_example
        The stdout should include 'ABORTED'
        The stdout should include 'FAILED'
      End
    End

    Context 'when example is not execution target'
      prepare() { shellspec_invoke_example() { echo 'invoke_example'; }; }
      BeforeRun SHELLSPEC_ENABLED='' SHELLSPEC_FILTER='' SHELLSPEC_DRYRUN=''

      It 'not invokes example'
        When run shellspec_example
        The stdout should not include 'invoke_example'
      End
    End

    Context 'when dry-run mode'
      prepare() { shellspec_invoke_example() { echo 'invoke_example'; }; }
      BeforeRun SHELLSPEC_ENABLED=1 SHELLSPEC_FILTER=1 SHELLSPEC_DRYRUN=1

      It 'always succeeds'
        When run shellspec_example
        The stdout should not include 'invoke_example'
        The stdout should include 'EXAMPLE'
        The stdout should include 'SUCCEEDED'
      End
    End
  End

  Describe "shellspec_invoke_example()"
    expectation() { shellspec_on EXPECTATION; shellspec_off NOT_IMPLEMENTED; }
    mock() {
      shellspec_output() { echo "$1"; }
      shellspec_yield0() { echo "yield"; block; }
    }
    BeforeRun SHELLSPEC_BLOCK_NO=0 mock

    It 'skippes the all if skipped outside of example'
      prepare() { shellspec_on SKIP; }
      BeforeRun prepare
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'SKIP'
      The stdout line 3 should equal 'SKIPPED'
    End

    It 'skipps the rest if skipped inside of example'
      block() { shellspec_skip 1; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'SKIP'
      The stdout line 4 should equal 'SKIPPED'
    End

    It 'is fail if failed before skipping'
      block() { expectation; shellspec_on FAILED; shellspec_skip 1; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'SKIP'
      The stdout line 4 should equal 'FAILED'
    End

    It 'is unimplemented if there is nothing inside of example'
      block() { :; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'NOT_IMPLEMENTED'
      The stdout line 4 should equal 'TODO'
    End

    It 'is failed if FAILED switch is on'
      block() { expectation; shellspec_on FAILED; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'FAILED'
    End

    It 'is warned and be status unhandled if UNHANDLED_STATUS switch is on'
      block() { expectation; shellspec_on UNHANDLED_STATUS; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'UNHANDLED_STATUS'
      The stdout line 4 should equal 'WARNED'
    End

    It 'is warned and be stdout unhandled if UNHANDLED_STDOUT switch is on'
      block() { expectation; shellspec_on UNHANDLED_STDOUT; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'UNHANDLED_STDOUT'
      The stdout line 4 should equal 'WARNED'
    End

    It 'is warned and be stderr unhandled if UNHANDLED_STDOUT switch is on'
      block() { expectation; shellspec_on UNHANDLED_STDERR; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'UNHANDLED_STDERR'
      The stdout line 4 should equal 'WARNED'
    End

    It 'is success if example ends successfully'
      block() { expectation; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'SUCCEEDED'
    End

    It 'is todo if FAILED and PENDING switch is on'
      block() { expectation; shellspec_on FAILED PENDING; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'TODO'
    End

    It 'is fixed if PENDING switch is on but not FAILED'
      block() { expectation; shellspec_on PENDING; }
      When run shellspec_invoke_example
      The stdout line 1 should equal 'EXAMPLE'
      The stdout line 2 should equal 'yield'
      The stdout line 3 should equal 'FIXED'
    End
  End

  Describe "shellspec_when()"
    init() {
      shellspec_off EVALUATION EXPECTATION
      shellspec_on NOT_IMPLEMENTED
    }

    mock() {
      shellspec_output() { echo "output:$1"; }
      shellspec_statement_evaluation() { :; }
      shellspec_on() { echo "on:$*"; }
      shellspec_off() { echo "off:$*"; }
    }

    It 'calls evaluation'
      BeforeRun init mock
      When run shellspec_when call true
      The stdout should include 'off:NOT_IMPLEMENTED'
      The stdout should include 'on:EVALUATION'
      The stdout should include 'output:EVALUATION'
    End

    It 'is syntax error when evaluation missing'
      BeforeRun init mock
      When run shellspec_when
      The stdout should include 'off:NOT_IMPLEMENTED'
      The stdout should include 'on:EVALUATION'
      The stdout should include 'on:FAILED'
      The stdout should include 'output:SYNTAX_ERROR'
    End

    It 'is syntax error when already executed evaluation'
      prepare() { shellspec_on EVALUATION; }
      BeforeRun init prepare mock
      When run shellspec_when call true
      The stdout line 1 should equal 'off:NOT_IMPLEMENTED'
      The stdout line 2 should equal 'output:SYNTAX_ERROR_EVALUATION'
      The stdout line 3 should equal 'on:FAILED'
    End

    It 'is syntax error when already executed expectation'
      prepare() { shellspec_on EXPECTATION; }
      BeforeRun init prepare mock
      When run shellspec_when
      The stdout should include 'off:NOT_IMPLEMENTED'
      The stdout should include 'on:EVALUATION'
      The stdout should include 'on:FAILED'
      The stdout should include 'output:SYNTAX_ERROR'
    End
  End

  Describe "shellspec_statement()"
    shellspec__statement_() { echo 'called'; }
    inspect() {
      shellspec_if SYNTAX_ERROR && echo 'SYNTAX_ERROR:on' || echo 'SYNTAX_ERROR:off'
      shellspec_if FAILED && echo 'FAILED:on' || echo 'FAILED:off'
    }
    AfterRun inspect

    It 'calls statement'
      When run shellspec_statement _statement_ dummy
      The stdout should include 'SYNTAX_ERROR:off'
      The stdout should include 'FAILED:off'
      The stdout should include 'called'
    End

    It 'is syntax error when statement raises syntax error'
      shellspec__statement_() { shellspec_on SYNTAX_ERROR; }
      When run shellspec_statement _statement_ dummy
      The stdout should include 'SYNTAX_ERROR:on'
      The stdout should include 'FAILED:on'
      The stdout should not include 'called'
    End

    It 'does not call statement when already skipped'
      prepare() { shellspec_on SKIP; }
      BeforeRun prepare
      When run shellspec_statement _statement_ dummy
      The stdout should not include 'called'
    End
  End

  Describe "shellspec_the()"
    prepare() { shellspec_on NOT_IMPLEMENTED; }

    mock() {
      shellspec_statement_preposition() { echo expectation; }
      shellspec_on() { echo "on:$*"; }
      shellspec_off() { echo "off:$*"; }
    }

    It 'calls expectation'
      BeforeRun prepare mock
      When run shellspec_the expectation
      The stdout should include 'off:NOT_IMPLEMENTED'
      The stdout should include 'on:EXPECTATION'
      The stdout should include 'expectation'
    End
  End

  Describe "shellspec_skip()"
    init() { SHELLSPEC_EXAMPLE_NO=1; }
    mock() {
      shellspec_output() { echo "output:$1"; }
    }
    inspect() {
      shellspec_if SKIP && echo 'SKIP:on' || echo 'SKIP:off'
      echo "skip_id:${SHELLSPEC_SKIP_ID-[unset]}"
      echo "skip_reason:${SHELLSPEC_SKIP_REASON-[unset]}"
      echo "example_no:${SHELLSPEC_EXAMPLE_NO-[unset]}"
    }
    BeforeRun init mock
    AfterRun inspect

    It 'skips example when inside of example'
      When run shellspec_skip 123 "reason"
      The stdout should include 'output:SKIP'
      The stdout should include 'SKIP:on'
      The stdout should include 'skip_id:123'
      The stdout should include 'skip_reason:reason'
      The stdout should include 'example_no:1'
    End

    It 'skips example when outside of example'
      init() { SHELLSPEC_EXAMPLE_NO=; }
      When run shellspec_skip 123 "skip reason"
      The stdout line 1 should equal 'SKIP:on'
    End

    It 'do nothing when already skipped'
      prepare() { shellspec_on SKIP; }
      BeforeRun prepare
      When run shellspec_skip 123 "skip reason"
      The stdout should not include 'output:SKIP'
      The stdout should include 'SKIP:on'
      The stdout should include 'skip_id:[unset]'
      The stdout should include 'skip_reason:[unset]'
      The stdout should include 'example_no:1'
    End

    It 'skips example when satisfy condition'
      When run shellspec_skip 123 if "reason" true
      The stdout should include 'output:SKIP'
      The stdout should include 'SKIP:on'
    End

    It 'does not skip example when not satisfy condition'
      When run shellspec_skip 123 if "reason" false
      The stdout should not include 'output:SKIP'
      The stdout should include 'SKIP:off'
    End
  End

  Describe "shellspec_pending()"

    init() { SHELLSPEC_EXAMPLE_NO=1; }
    mock() {
      shellspec_output() { echo "output:$1"; }
    }
    inspect() {
      shellspec_if PENDING && echo 'pending:on' || echo 'pending:off'
    }
    BeforeRun init mock
    AfterRun inspect

    It 'pending example when inside of example'
      When run shellspec_pending
      The stdout should include 'output:PENDING'
      The stdout should include 'pending:on'
    End

    It 'does not pending example when already failed'
      prepare() { shellspec_on FAILED; }
      BeforeRun prepare
      When run shellspec_pending
      The stdout should include 'output:PENDING'
      The stdout should include 'pending:off'
    End

    It 'does not pending example when already skipped'
      prepare() { shellspec_on SKIP; }
      BeforeRun prepare
      When run shellspec_pending
      The stdout should not include 'output:PENDING'
      The stdout should include 'pending:off'
    End

    It 'does not pending example when outside of example'
      prepare() { SHELLSPEC_EXAMPLE_NO=; }
      BeforeRun prepare
      When run shellspec_pending
      The stdout should not include 'output:PENDING'
      The stdout should include 'pending:on'
    End
  End

  Describe "Include"
    Include "$LIB/include.sh" # comment
    Before 'unset __SOURCED__'

    It 'includes script'
      The result of "foo()" should eq "foo"
    End

    It 'supplies __SOURCED__ variable'
      The output should be blank
      The result of "get_sourced()" should eq "$LIB/include.sh"
    End

    It 'handles readonly correctly'
      The variable value should eq 123
    End
  End

  Describe "shellspec_logger()"
    It 'outputs to logfile'
      BeforeCall SHELLSPEC_LOGFILE="$SHELLSPEC_TMPBASE/test-logfile"
      When call shellspec_logger "logger test"
      The contents of file "$SHELLSPEC_LOGFILE" should eq "logger test"
    End

    It 'sleeps to make the log easy to read'
      sleep() { echo sleep; }
      BeforeCall SHELLSPEC_LOGFILE=/dev/null
      When call shellspec_logger "logger test"
      The stdout should eq "sleep"
    End
  End

  Describe "shellspec_intercept()"
    It 'registor interceptor with default name'
      When call shellspec_intercept foo
      The variable SHELLSPEC_INTERCEPTOR should eq "|foo:__foo__|"
    End

    It 'registor interceptor with specified name'
      When call shellspec_intercept foo:bar
      The variable SHELLSPEC_INTERCEPTOR should eq "|foo:bar|"
    End

    It 'registor interceptor with same name'
      When call shellspec_intercept foo:
      The variable SHELLSPEC_INTERCEPTOR should eq "|foo:foo|"
    End

    It 'registor multiple interceptors at once'
      When call shellspec_intercept foo bar
      The variable SHELLSPEC_INTERCEPTOR should eq "|foo:__foo__|bar:__bar__|"
    End
  End

  Describe "Set"
    Context 'when set errexit on'
      Set errexit:on
      It 'sets shell option'
        When call echo "$-"
        The stdout should include "e"
      End
    End

    Context 'when set errexit off'
      Set errexit:off
      It 'sets shell option'
        When call echo "$-"
        The stdout should not include "e"
      End
    End
  End

  Describe 'BeforeCall / AfterCall'
    before() { echo before; }
    after() { echo after; }
    foo() { echo foo; }
    BeforeCall before
    AfterCall after

    It 'called before / after expectation'
      When call foo
      The line 1 of stdout should eq before
      The line 2 of stdout should eq foo
      The line 3 of stdout should eq after
    End

    It 'can be specified multiple'
      BeforeCall 'echo before2'
      AfterCall 'echo after2'
      When call foo
      The line 1 of stdout should eq before
      The line 2 of stdout should eq before2
      The line 3 of stdout should eq foo
      The line 4 of stdout should eq after2
      The line 5 of stdout should eq after
    End

    It 'calls same scope with evaluation'
      before() { value='before'; }
      foo() { value="$value foo"; }
      after() { echo "$value after"; }
      When call foo
      The stdout should eq "before foo after"
    End

    Describe 'BeforeCall'
      It 'failed and evaluation not call'
        before() { return 123; }
        When call foo
        The stdout should not include 'foo'
        The status should eq 123
        The stderr should be present
      End
    End

    Describe 'AfterCall'
      Context 'errexit is on'
        Set errexit:on
        It 'not called when evaluation failure'
          foo() { echo foo; false; }
          When call foo
          The line 1 of stdout should eq before
          The line 2 of stdout should eq foo
          The line 3 of stdout should be undefined
          The status should be failure
        End
      End

      Context 'errexit is off'
        Set errexit:off
        It 'not called when evaluation failure'
          foo() { echo foo; false; }
          When call foo
          The line 1 of stdout should eq before
          The line 2 of stdout should eq foo
          The line 3 of stdout should be undefined
          The status should be failure
        End
      End

      It 'fails cause evaluation to be failure'
        after() { return 123; }
        When call foo
        The status should eq 123
        The line 1 of stdout should eq 'before'
        The line 2 of stdout should eq 'foo'
        The stderr should be present
      End
    End
  End

  Describe 'BeforeRun / AfterRun'
    before() { echo before; }
    after() { echo after; }
    foo() { echo foo; }
    BeforeRun before
    AfterRun after

    It 'run before / after expectation'
      When run foo
      The line 1 of stdout should eq before
      The line 2 of stdout should eq foo
      The line 3 of stdout should eq after
    End

    It 'can be specified multiple'
      BeforeRun 'echo before2'
      AfterRun 'echo after2'
      When run foo
      The line 1 of stdout should eq before
      The line 2 of stdout should eq before2
      The line 3 of stdout should eq foo
      The line 4 of stdout should eq after2
      The line 5 of stdout should eq after
    End

    It 'runs same scope with evaluation'
      before() { value='before'; }
      foo() { value="$value foo"; }
      after() { echo "$value after"; }
      When run foo
      The stdout should eq "before foo after"
    End

    Describe 'BeforeRun'
      It 'failed and evaluation not run'
        before() { return 123; }
        When run foo
        The stdout should not include 'foo'
        The status should eq 123
        The stderr should be present
      End
    End

    Describe 'AfterRun'
      Context 'errexit is on'
        Set errexit:on
        It 'not run when evaluation failure'
          foo() { echo foo; false; }
          When run foo
          The line 1 of stdout should eq before
          The line 2 of stdout should eq foo
          The line 3 of stdout should be undefined
          The status should be failure
        End
      End

      Context 'errexit is off'
        Set errexit:off
        It 'not run when evaluation failure'
          foo() { echo foo; false; }
          When run foo
          The line 1 of stdout should eq before
          The line 2 of stdout should eq foo
          The line 3 of stdout should be undefined
          The status should be failure
        End
      End

      It 'fails cause evaluation to be failure'
        after() { return 123; }
        When run foo
        The status should eq 123
        The line 1 of stdout should eq 'before'
        The line 2 of stdout should eq 'foo'
        The stderr should be present
      End
    End
  End
End
