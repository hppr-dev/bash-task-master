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

class Command(object):

    def __init__(self, name, data_dict):
        self.name = name
        data_dict = dict() if data_dict == None else data_dict
        self.description = data_dict.get('description') or 'No description'
        self.options = ArgumentList(data_dict.get('optional'))
        self.requirements = ArgumentList(data_dict.get('required'), required=True)
        self.aliases = data_dict.get('aliases', '').split(',')

    def __eq__(self, other):
        if type(other) == str:
            if is_a_match(self.name)(other):
                self.name = other
                return True
            return  self.aliases != [''] and other in self.aliases
        return self.name == other.name

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

    def compute_requirements(self):
        return self.requirements

    def compute_options(self):
        return self.options
    
    def parse(self, arguments):
        computed_requirements = self.compute_requirements()
        computed_options = self.compute_options()
        optional_args, required_args = [],[]
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

    def __repr__(self):
        return self.name


class Task(Command):
    def __init__(self, name, task_dict):
        super(Task, self).__init__(name, task_dict)
        if task_dict.get('subcommands') != None:
            self.subcommands = dict([(sub, Command(sub, task_dict.get(sub, dict()))) for sub in task_dict.get('subcommands','').split(',')])
        else:
            subcommands = set(task_dict.keys()) - set(['optional', 'required', 'description'])
            self.subcommands = dict([(sub, Command(sub, task_dict[sub])) for sub in subcommands])

    def compute_requirements(self):
        return self.requirements if self.sub_obj == '' else self.requirements + self.sub_obj.requirements

    def compute_options(self):
        return self.options if self.sub_obj == '' else self.options + self.sub_obj.options

    def parse(self, arguments):
        if len(arguments) == 0:
            if not 'None' in self.subcommands and self.subcommands != []:
                fail('Missing subcommand, add "none" to subcommands to allow calling without a subcommand')
            else:
                subcommand = 'none'
        if arguments[0][0] == '-':
            subcommand = 'none'
        else:
            subcommand = arguments.pop(0)
        self.sub_obj = next((sub for sub in self.subcommands.values() if subcommand == sub), Command('', {}))
        if subcommand != 'none':
            exports.append('TASK_SUBCOMMAND="%s"' % (self.sub_obj.name))
        if self.sub_obj == '':
            fail("Subcommand %s does not exist" % (subcommand))
        super(Task, self).parse(arguments)
        return True

    def help_str(self):
        helpstr = 'task %s [ %s ]:\n' % (self.name, '|'.join(self.subcommands.keys()))

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
                return fail('Could not find argument %s in yaml description' % (arg))
            if arg_obj.arg_type == 'bool':
                if not arg_obj.parse():
                    return fail('Could not validate %s' % (arg))
            else:
                if i+1 >= len(arguments):
                    return fail('Expected a value with %s and got none' % (arg))
                if not arg_obj.parse(arguments[i+1]):
                    return fail('Could not validate %s' % (arg))
        if self.required:
            missing_args = [ arg for arg in self.arguments if not arg.in_list(arguments) ]
            if len(missing_args) != 0:
                return fail("Missing required arg(s) %s " % (str([a.long_arg for a in missing_args])))
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

if __name__ == "__main__":
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
