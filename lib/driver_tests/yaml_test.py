import os
import sys
from  unittest import TestCase, main


sys.path.append(os.path.abspath("../"))
from yaml_driver import TaskList, Command, Task, ArgumentList, Argument, exports

class TaskListTest(TestCase):

    def test_task_list(self):
        pass

class CommandTest(TestCase):

    def test_command(self):
        pass

class Task(TestCase):

    def test_task(self):
        pass

class ArgumentListTest(TestCase):

    def test_argument_list(self):
        pass

class ArgumentTest(TestCase):

    def test_argument(self):
        pass




if __name__ == "__main__":
    main()
