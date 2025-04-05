"""
development utils for the nmt py modules

Note:
     install env: `conda env create -f ./inst/py_requirements.yml --prefix ./conda_env_nmt`
"""

"""other utilities"""

# ------ modules ------
import os
import sys
import logging
import re
from typing import Union, Optional
from py_utils.py_other_utils import colr


# ------ classes -------
class VariableNotFoundError(ValueError):
    pass


class FileError(ValueError):
    pass


class TokenValueError(ValueError):
    pass


class MyLogger(object):
    """custom logger"""

    def __init__(self, logger_name: Optional[str] = __name__,
                 console_out: bool = True, console_log_format: Optional[str] = '\n%(asctime)s:%(name)s:%(levelname)s:%(message)s',
                 file_name: Optional[str] = None, file_log_format: Optional[str] = '\n%(asctime)s:%(name)s:%(levelname)s:%(message)s'):
        """
        # Details\n
            - Logger name (`logger_name`) behaviour: by default, the `__name__` variable is used, i.e. current py file name.
                If `None`, the logger name is `Logging` (class name).\n
            - When `file_name=None`,
                - and `console_out=True`: no log file is created. Logger output streamed to sys.stdout.
                - and `console_out=False`: log file is created with file name `f'{Logging.__name__}.log'`.\n
        """
        # -- argument check and vars --
        self.logger_name = logger_name
        self.c_out = console_out
        if file_name:
            self.file_name = os.path.normpath(
                os.path.abspath(os.path.expanduser(file_name)))
        elif console_out is False:
            self.file_name = f'{MyLogger.__name__}.log'
            self.file_name = os.path.normpath(
                os.path.abspath(os.path.expanduser(self.file_name)))
        else:
            self.file_name = None

        self.c_fmt = console_log_format
        self.f_fmt = file_log_format

        # -- initiate logger --
        # print(f'file name set to {self.file_name}')
        # print(f'console out set to {self.c_out}')
        self._logger_setup()

    def _logger_setup(self):
        """initiate logger configeration"""
        if self.logger_name:
            logger = logging.getLogger(self.logger_name)
        else:
            logger = logging.getLogger(MyLogger.__name__)

        # - formatter -
        c_formatter = logging.Formatter(self.c_fmt)
        f_formatter = logging.Formatter(self.f_fmt)

        # - handlers -
        if self.c_out:
            ch = logging.StreamHandler(sys.stdout)
            # ch.setLevel(logging.INFO)
            ch.setFormatter(c_formatter)
        else:
            ch = None

        try:
            fh = logging.FileHandler(self.file_name)
            fh.setLevel(logging.DEBUG)
            fh.setFormatter(f_formatter)
        except TypeError:
            fh = None

        # - finalize logger -
        logger.setLevel(logging.DEBUG)
        # print(f'number of handlers: {len(logger.handlers)}')
        logger.handlers = []  # clear any potential redundant handlers

        if ch:
            logger.addHandler(ch)

        if fh:
            logger.addHandler(fh)

        self.logger = logger

    def debug(self, message: str, *lines):
        if self.c_out and self.file_name is None:
            msg = f'{colr.BLUE_B} ' + message + \
                f'{colr.BLUE}\n'.join(lines) + f'{colr.ENDC}'
        else:
            msg = f' {message}' + '\n'.join(lines)
        self.logger.debug(msg)

    def info(self, message: str, *lines):
        msg = f' {message}'+'\n'.join(lines)
        self.logger.info(msg)

    def warning(self, message: str, *lines):
        if self.c_out and self.file_name is None:
            msg = f'{colr.YELLOW_B} ' + message + \
                f'{colr.YELLOW}\n'.join(lines) + f'{colr.ENDC}'
        else:
            msg = f' {message}' + '\n'.join(lines)
        self.logger.warning(msg)

    def error(self, message: str, *lines):
        if self.c_out and self.file_name is None:
            msg = f'{colr.RED_B} ' + message + \
                f'{colr.RED}\n'.join(lines) + f'{colr.ENDC}'
        else:
            msg = f' {message}' + '\n'.join(lines)
        self.logger.error(msg)
        sys.exit(2)

    def exception(self, message: str, *lines):
        if self.c_out and self.file_name is None:
            msg = f'{colr.RED_B} ' + message + \
                f'{colr.RED}\n'.join(lines) + f'{colr.ENDC}'
        else:
            msg = f' {message}' + '\n'.join(lines)
        self.logger.exception(msg)


# ------ functions -------
def error(message, *lines):
    """
    stole from: https://github.com/alexjc/neural-enhance
    """
    string = "\n{}ERROR: " + message + "{}\n" + \
        "\n".join(lines) + ("{}" if lines else "{}")
    print(string.format(colr.RED_B, colr.RED, colr.ENDC))
    sys.exit(2)


def warn(message, *lines):
    """
    stole from: https://github.com/alexjc/neural-enhance
    """
    string = '\n{}WARNING: ' + message + '{}\n' + '\n'.join(lines) + '{}'
    print(string.format(colr.YELLOW_B, colr.YELLOW, colr.ENDC))


def excpt(message, *lines):
    """
    stole from: https://github.com/alexjc/neural-enhance
    """
    string = '\n{}EXCEPTION: ' + message + '{}\n' + '\n'.join(lines) + '{}'
    print(string.format(colr.RED_B, colr.RED, colr.ENDC))


def set_global_logging_level(level=logging.ERROR, prefices=[""]):
    """
    NOTE: does not work




    Override logging levels of different modules based on their name as a prefix.
    It needs to be invoked after the modules have been loaded so that their loggers have been initialized.

    Args:
        - level: desired level. e.g. logging.INFO. Optional. Default is logging.ERROR
        - prefices: list of one or more str prefices to match (e.g. ["transformers", "torch"]). Optional.
          Default is `[""]` to match all active loggers.
          The match is a case-sensitive `module_name.startswith(prefix)`

    Stole from: https://github.com/huggingface/transformers/issues/3050
    """
    prefix_re = re.compile(fr'^(?:{ "|".join(prefices) })')
    for name in logging.root.manager.loggerDict:
        if re.match(prefix_re, name):
            logging.getLogger(name).setLevel(level)