#!/usr/bin/python

import yaml
import sys
import os
import re

exports=[]

is_a_match = lambda regex: lambda m: re.match(regex, m) != None
valid_types = {
    'str': is_a_match('^.+$'),
    'int': is_a_match('^[0-9]+$'),
    'nowhite': is_a_match('^[\S]+$'),
    'upper': is_a_match('^[A-Z]+$'),
    'lower': is_a_match('^[a-z]+$'),
    'single': is_a_match("^.{1}$"),
    'ip': is_a_match("^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"),
    'bool': lambda x : True
}
def splay_args(arg_list):
    ret_list = []
    for i in arg_list:
        if '--' == i[0:2]:
            ret_list += [i]
        elif '-' == i[0]:
            ret_list += ['-' + a for a in i[1:]]
        else:
            ret_list += [i]
    return ret_list

def fail(msg):
    sys.stderr.write('ERROR: ' + str(msg) +'\n')
    sys.stderr.flush()
    sys.exit(1)

def warn(msg):
    sys.stderr.write('WARN: ' + str(msg) +'\n')
    sys.stderr.flush()

class TaskList(object):
    def __init__(self, spec_dict):
        if spec_dict:
            self.tasks = [Task(task, spec_dict[task]) for task in spec_dict.keys()]
        else:
            self.tasks = []

    def parse(self, arguments):
        task = next((t for t in self.tasks if t.name == arguments[0]), None)
        if not task:
            warn('Task not found: %s' % (arguments[0]))
            exports.append('TASK_SUBCOMMAND="%s"' % (arguments[0]))
            return True
        return task.parse(splay_args(arguments[1:]))

    def help_str(self, task):
        task_obj = next((t for t in self.tasks if t.name == task), None)
        if task_obj == None:
            return 'Task %s not found' % (task)
        return task_obj.help_str()


class Task(object):
    def __init__(self, name, task_dict):
        self.name = name
        task_dict = dict() if task_dict == None else task_dict
        self.description = task_dict.get('description') or 'No description'
        self.subcommands = task_dict.get('subcommands')
        if self.subcommands != None:
            self.subcommands = self.subcommands.split(',')
        else:
            self.subcommands = ['']
        self.options = {'root' : ArgumentList(task_dict.get('optional'))}
        self.requirements = {'root': ArgumentList(task_dict.get('required'), required=True)}
        for sub in self.subcommands:
            sub_dict = task_dict.get(sub)
            if sub_dict != None:
                self.options[sub] = ArgumentList(sub_dict.get('optional'))
                self.requirements[sub] = ArgumentList(sub_dict.get('required'), required=True)

    def get_options(self, subcommand):
        sub_options = self.options.get(subcommand)
        if sub_options != None:
            return self.options['root'] + sub_options
        return self.options['root']

    def get_requirements(self, subcommand):
        sub_requirements = self.requirements.get(subcommand)
        if sub_requirements != None:
            return self.requirements['root'] + sub_requirements
        return self.requirements['root']

    def parse(self, arguments):
        if len(arguments) == 0:
            if not 'None' in self.subcommands and self.subcommands != ['']:
                fail('Missing subcommand, add "none" to subcommands to allow calling without a subcommand')
            else:
                subcommand = 'none'
        if arguments[0][0] == '-':
            subcommand = 'none'
        else:
            subcommand = arguments.pop(0)
            exports.append('TASK_SUBCOMMAND="%s"' % (subcommand))
        if not any(map(lambda x: is_a_match(x)(subcommand), self.subcommands)):
            fail("Subcommand %s does not exist" % (subcommand))
        computed_requirements = self.get_requirements(subcommand)
        computed_options = self.get_options(subcommand)
        required_args = []
        optional_args = []
        for i in range(len(arguments)):
            if arguments[i][0] != '-':
                continue
            if arguments[i] in computed_requirements.get_available_arguments():
                required_args.append(arguments[i])
                if i+1 < len(arguments) and arguments[i+1][0] != '-':
                    required_args.append(arguments[i+1])
            elif arguments[i] in computed_options.get_available_arguments():
                optional_args.append(arguments[i])
                if i+1 < len(arguments) and arguments[i+1][0] != '-':
                    optional_args.append(arguments[i+1])
            else:
                fail('Argument %s not recognized' % (arguments[i])) 

        computed_options.parse(optional_args)
        computed_requirements.parse(required_args)
        return True

    def help_str(self):
        helpstr = 'task %s [ %s ]:\n' % (self.name, '|'.join(self.subcommands))
        helpstr += ' ' + ( self.description or 'No description') + '\n' if self.description else ''
        helpstr += self.__arg_str__('root')
        for sub in self.subcommands:
            addition = self.__arg_str__(sub)
            if addition != '':
                helpstr += 'task %s %s:\n' % (self.name, sub)
                helpstr += '  ' + ( self.description or 'No description' )  + '\n' 
                helpstr += addition + '\n'
        return helpstr

    def __arg_str__(self, sub):
        reqs = self.requirements.get(sub)
        opts = self.options.get(sub)
        helpstr = ''
        if reqs and not reqs.empty():
            helpstr += '  Requirements:\n'
            for arg in reqs:
                helpstr += '\t  ' + arg.help_str()
        if opts and not opts.empty():
            helpstr += '  Options:\n'
            for arg in self.options.get(sub, []):
                helpstr += '\t  ' + arg.help_str()
        return helpstr

class ArgumentList(object):
    def __init__(self, arg_dict, required=False):
        self.arguments = []
        self.required = required
        self.arg_dict = arg_dict if arg_dict != None else dict()
        for long_arg, values in self.arg_dict.items():
            if type(values) == dict:
                self.arguments.append(Argument(long_arg, values.get('short'), values.get('type'), (values.get('description') or 'No description')))
            else:
                self.arguments.append(Argument(long_arg, *values.split(',')))

    def get_available_arguments(self):
        return [ a.long_arg for a in self.arguments ] + [a.short_arg for a in self.arguments]

    def __add__(self, other):
        self.arguments += other.arguments
        return self 

    def parse(self, arguments):
        for i in range(len(arguments)):
            arg =  arguments[i]
            if '-' !=  arg[0]:
                continue
            arg_obj = next((a for a in self.arguments if arg == a.long_arg or arg == a.short_arg), None)
            if arg_obj == None:
                fail('Could not find argument %s in yaml description' % (arg))
            if arg_obj.arg_type == 'bool':
                if not arg_obj.parse():
                    fail('Could not validate %s' % (arg))
            else:
                if i+1 >= len(arguments):
                    fail('Expected a value with %s and got none' % (arg))
                if not arg_obj.parse(arguments[i+1]):
                    fail('Could not validate %s' % (arg))
        if self.required:
            missing_args = [ arg for arg in self.arguments if not arg.in_list(arguments) ]
            if len(missing_args) != 0:
                fail("Missing required arg(s) %s " % (str([a.long_arg for a in missing_args])))
        return True

    def __iter__(self):
        return self.arguments.__iter__()

    def empty(self):
        return self.arguments == []
        

class Argument(object):
    def __init__(self, long_arg, short_arg='', arg_type='str', description='No description'):
        if not arg_type in valid_types.keys():
            fail("Argument type %s not supported" % (arg_type))
        self.long_arg = "--" + long_arg.strip()
        self.short_arg = "-" + short_arg.strip()
        self.arg_type = arg_type.strip()
        self.description = description.strip()

    def parse(self, arguments=1):
        return self.validate(arguments)

    def validate(self, argument):
        exports.append('ARG_%s="%s"' % (self.long_arg[2:].upper(), argument))
        return valid_types[self.arg_type](argument)
  
    def __equals__(self, arg):
        return self.long_arg == args or self.short_arg

    def in_list(self, args):
        return self.long_arg in args or self.short_arg in args

    def help_str(self):
        return '%s (%s), %s (%s)\t%s\n' % (self.long_arg, self.arg_type, self.short_arg, self.arg_type, self.description)

args_file = sys.argv[1]
task_args = sys.argv[2:]

with open(sys.argv[1], 'r') as f:
    try:
        spec = TaskList(yaml.load(f))
    except yaml.YAMLError as exc:
        fail(str(exc))


if 'help' == task_args[0]:
    task_args.remove('help')
    print spec.help_str(task_args[0])
elif not spec.parse(task_args):
    fail('Arguments not validated')
else:
    for var in exports:
        print var
