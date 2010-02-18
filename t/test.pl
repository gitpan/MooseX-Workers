package MXWTest;
use Moose;
with 'MooseX::Workers';

sub POE::Kernel::ASSERT_DEFAULT   { 0 }  # 1
sub POE::Kernel::TRACE_DEFAULT    { 0 }  # 0
sub POE::Kernel::TRACE_EVENTS     { 0 }  # 0
sub POE::Kernel::TRACE_SIGNALS    { 0 }  # 0
sub POE::Kernel::TRACE_SESSIONS   { 0 }  # 0
sub POE::Kernel::TRACE_REFCNT     { 0 }  # 0
sub POE::Kernel::TRACE_FILES      { 0 }  # 0
sub POE::Kernel::CATCH_EXCEPTIONS { 0 }  # 1
sub POE::Session::ASSERT_STATES   { 0 }  # 1

use MooseX::Workers::Job;
use POE;

use POE qw(Wheel::Run Filter::Reference);

has 'scheduler_session' => (
    isa             => 'Int',
    is              => 'rw',
);

has job => (
    isa             => 'MooseX::Workers::Job',
    is              => 'ro',
    default         => sub {
        MooseX::Workers::Job->new(
            name => 'test',
            command => sub { print "ping" }
        )
    },
);

sub run {
        my $self = shift;

        $self->max_workers( 3 );
        $self->enqueue( $self->job );

        my $session_id = POE::Session->create(
                inline_states => {
                        _start => sub {
                                print "starting scheduler session\n";
                                $_[KERNEL]->refcount_increment( $_[SESSION] );
                        },
                        _stop => sub { print "scheduler sessions stopped\n"; },
                        enqueue_job => sub { scheduler_enqueue_job() },
                        delay_job =>   sub { scheduler_delay_job() },
                },
               # object_states => [
               #         $self => {
               #                 enqueue_job => "scheduler_enqueue_job",
               #                 delay_job => "scheduler_delay_job",
               #         },
               # ],
        )->ID;
        $self->scheduler_session($session_id);

        print "created session for scheduler; ID: ".$self->scheduler_session."\n";

        POE::Kernel->run;
}

sub scheduler_delay_job {
    my $job = $_[ARG0];

    print "received a job delay request\n";
    # accept a job from another session and schedule to push that job
    # onto our worker queue in 10 seconds time.
    $_[KERNEL]->alarm( 'enqueue_job', 10, $job );
}

sub scheduler_enqueue_job {
    my ($job, $self) = @_[ARG0, OBJECT];

    # simply enqueue the supplied job in our worker processing queue
    $self->enqueue( $job );
}

sub worker_started {
    my ($self, $job) = @_;
    print scalar(localtime)." -- ";
    printf 'Starting job for %s(%s,%s)', $job->name, $job->ID, $job->PID;
    print "\n";
}

sub worker_done    {
    my ($self, $job) = @_;
    print scalar(localtime)." -- ";
    printf 'Completed job for %s(%s,%s)', $job->name, $job->ID, $job->PID;
    print "\n";
}

sub sig_child      {
    my ($self, $wheelid, $exit_val) = @_;
    my $job = $self->Engine->get_job($wheelid);

    $exit_val >>= 8; # get the real exit value
    printf('worker %s(%s,%s) exited: %d',
        $job->name, $job->ID, $job->PID, $exit_val),
    print "\n";

    $self->requeue_job($job);
}

sub requeue_job {
    my ($self, $job) = @_;
    print "posting to delay_job@".$self->scheduler_session." - job ".$job->name."\n";
    $DB::single = 1;
    POE::Kernel->post( $self->scheduler_session, 'delay_job', $job ) or die @!;
}


package main;
MXWTest->new->run;

