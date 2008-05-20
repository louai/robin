import imp, string, os.path, __builtin__

libdir = os.path.dirname(__file__)
model = ["RELEASE", "DEBUG"][os.environ.has_key("ROBIN_DEBUG")]
ver = "1.0"

from griffin import uname, arch, soext, sopre, platspec, pyspec

target = "%(sopre)srobin_pyfe%(platspec)s-%(ver)s%(pyspec)s%(soext)s" % vars()

__pyfile__ = __file__
imp.load_dynamic("robin", os.path.join(libdir, target))
__file__ = __pyfile__
__builtin__.double = double
__builtin__.char = char
__builtin__.longlong = longlong
__builtin__.ulong = ulong
__builtin__.uint = uint
__builtin__.uchar = uchar
__builtin__.ulonglong = ulonglong
__builtin__.schar = schar

ldinfo = { 'm': arch, 'so': soext, \
           'suffix': "", 'confdir': "." }

def here(file):
	import os
	if file.endswith(".pyc") and os.path.isfile(file[:-1]):
		file = file[:-1]
	return os.path.dirname(os.path.realpath(file)) 


def implement(tp):
	import warnings
	warnings.warn("robin.implement is deprecated")
	return tp

# Cleanup
del imp, os, libdir, target, __builtin__