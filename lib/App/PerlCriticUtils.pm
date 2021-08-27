package App::PerlCriticUtils;

use 5.010001;
use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

our %arg_policies = (
    policies => {
        schema => ['array*' => of=>'perl::modname*', min_len=>1],
        req    => 1,
        pos    => 0,
        greedy => 1,
        element_completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                ns_prefix=>'Perl::Critic::Policy', word=>$args{word});
        },
    },
);

our %arg_policy = (
    policy => {
        schema => 'perl::modname*',
        req    => 1,
        pos    => 0,
        completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                ns_prefix=>'Perl::Critic::Policy', word=>$args{word});
        },
    },
);

our %argopt_detail = (
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

$SPEC{pcplist} = {
    v => 1.1,
    summary => 'List installed Perl::Critic policy modules',
    args => {
        %argopt_detail,
    },
    examples => [
        {
            summary => 'List installed policies',
            argv => [],
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => 'List installed policies (show details)',
            argv => ['-l'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcplist {
    require PERLANCAR::Module::List;

    my %args = @_;

    my $mods = PERLANCAR::Module::List::list_modules(
        'Perl::Critic::Policy::', {list_modules=>1, recurse=>1});
    my @rows;
    my $resmeta = {};
    for my $mod (sort keys %$mods) {
        (my $name = $mod) =~ s/^Perl::Critic::Policy:://;
        if ($args{detail}) {
            require Module::Abstract;
            push @rows, {
                name => $name,
                abstract => Module::Abstract::module_abstract($mod),
            };
        } else {
            push @rows, $name;
        }
    }
    $resmeta->{'table.fields'} = [qw/name abstract/] if $args{detail};
    [200, "OK", \@rows, $resmeta];
}

$SPEC{pcppath} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl::Critic policy module',
    args => {
        %arg_policies,
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcppath {
    require Module::Path::More;
    my %args = @_;

    my $policies = $args{policies};
    my $res = [];
    my $found;

    for my $policy (@{$policies}) {
        my $mpath = Module::Path::More::module_path(
            module      => "Perl::Critic::Policy::$policy",
        );
        $found++ if $mpath;
        for (ref($mpath) eq 'ARRAY' ? @$mpath : ($mpath)) {
            push @$res, @$policies > 1 ? {policy=>$policy, path=>$_} : $_;
        }
    }

    if ($found) {
        [200, "OK", $res];
    } else {
        [404, "No such module"];
    }
}

$SPEC{pcpless} = {
    v => 1.1,
    summary => 'Show Perl::Critic policy module source code with `less`',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'less',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpless {
    require Module::Path::More;
    my %args = @_;
    my $policy = $args{policy};
    my $mpath = Module::Path::More::module_path(
        module => "Perl::Critic::Policy::$policy",
        find_pmc=>0, find_pod=>0, find_prefix=>0);
    if (defined $mpath) {
        system "less", $mpath;
        [200, "OK"];
    } else {
        [404, "Can't find policy $policy"];
    }
}

$SPEC{pcpcat} = {
    v => 1.1,
    summary => 'Print Perl::Critic policy module source code',
    args => {
        %arg_policies,
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpcat {
    require Module::Path::More;

    my %args = @_;
    my $policies = $args{policies};
    return [400, "Please specify at least one policy"] unless @$policies;

    my $has_success;
    my $has_error;
    for my $policy (@$policies) {
        my $path = Module::Path::More::module_path(
            module=>"Perl::Critic::Policy::$policy", find_pod=>0) or do {
                warn "pcpcat: No such policy '$policy'\n";
                $has_error++;
                next;
            };
        open my $fh, "<", $path or do {
            warn "pcpcat: Can't open '$path': $!\n";
            $has_error++;
            next;
        };
        print while <$fh>;
        close $fh;
        $has_success++;
    }

    if ($has_error) {
        if ($has_success) {
            return [207, "Some policies failed"];
        } else {
            return [500, "All policies failed"];
        }
    } else {
        return [200, "All policies OK"];
    }
}

$SPEC{pcpdoc} = {
    v => 1.1,
    summary => 'Show documentation of Perl::Critic policy module',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'perldoc',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpdoc {
    my %args = @_;
    my $policy = $args{policy};
    my @cmd = ("perldoc", "Perl::Critic::Policy::$policy");
    exec @cmd;
    # [200]; # unreachable
}

$SPEC{pcpman} = {
    v => 1.1,
    summary => 'Show manpage of Perl::Critic policy module',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'man',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpman {
    my %args = @_;
    my $policy = $args{policy};
    my @cmd = ("man", "Perl::Critic::Policy::$policy");
    exec @cmd;
    # [200]; # unreachable
}

1;
# ABSTRACT: Command-line utilities related to Perl::Critic

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
Perl::Critic:

#INSERT_EXECS_LIST

=cut
