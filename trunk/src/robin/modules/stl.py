from __future__ import generators
import robin, os.path

if os.path.islink(__file__): __file__ = os.readlink(__file__)
here = os.path.dirname(__file__)
machine = os.getenv("MACHINE")
lib = "librobin_stl" + robin.soext
robin.loadLibrary(__name__, lib)

reallist = list

ostringstream = std.ostringstream
ifstream = std.ifstream
ofstream = std.ofstream
string = std.string
string.__to__ = str

truetype = { double: float, long: int, ulong: int, uint: int, char: str, uchar: str}

def sum_tuples(tuplelst):
	sumlst = [0 for i in tuplelst[0]]
	for curtuple in tuplelst:
		for i in range(len(curtuple)):
			sumlst[i] = sumlst[i] + curtuple[i]
	return tuple(sumlst)

def make_vector_functor(vectype, volatile = False):
	def make_any_vector(lst, vectype = vectype):
		vec = vectype()
		for item in lst:
			vec.push_back(item)
		if volatile:
			vec.__owner__ = STLContainer.STLOwner(lst, vec)
		return vec

	return make_any_vector

def make_list_functor(listtype, volatile = False):
	def make_any_list(lst, listtype = listtype):
		l = listtype()
		for item in lst:
			l.push_back(item)
		if volatile:
			l.__owner__ = STLContainer.STLOwner(lst, l)
		return l

	return make_any_list

def make_set_functor(settype, volatile = False):
	def make_any_set(lst, settype = settype):
		set = settype()
		for item in lst:
			set.insert(item)
		if volatile:
			set.__owner__ = STLContainer.STLOwner(lst, set)
		return set

	return make_any_set

def make_container_weigher(el):
	def weigh_any_container(insight, el = el):
		if insight is el:
			w = (0, 1, 0, 0)
		else:
			w = robin.weighConversion(
				truetype.get(insight, insight),
				truetype.get(el, el))
			w = sum_tuples( [w, (0, 1, 0, 0)] )
		return w

	return weigh_any_container


def _vector_from_list(vl, el = None):
	if el:
		vl.__from__[[]] = make_vector_functor(vl), 2, make_container_weigher(el)
		vl.__from_volatile__[[]] = \
				make_vector_functor(vl, True), 2, make_container_weigher(el)
	else:
		vl.__from__[[]] = make_vector_functor(vl)
		vl.__from_volatile__[[]] = make_vector_functor(vl, True)
	vl.__getslice__ = lambda self, fr, to: [self[i] for i in xrange(fr,to)]

def _list_from_list(ll, el = None):
	if el:
		ll.__from__[[]] = make_list_functor(ll), 2, make_container_weigher(el)
		ll.__from_volatile__[[]] = \
				make_list_functor(ll, True), 2, make_container_weigher(el)
	else:
		ll.__from__[[]] = make_list_functor(ll)
		ll.__from_volatile__[[]] = make_list_functor(ll, True)
	ll.__len__ = lambda self: len([i for i in gen(self)])
	ll.__getitem__ = lambda self, index: [i for i in gen(self)][index]

def _set_from_list(sl, el = None):
	if el:
		sl.__from__[[]] = make_set_functor(sl), 2, make_container_weigher(el)
		sl.__from_volatile__[[]] = \
				make_set_functor(sl, True), 2, make_container_weigher(el)
	else:
		sl.__from__[[]] = make_set_functor(sl)
		sl.__from_volatile__[[]] = make_set_functor(sl, True)
	sl.__len__ = lambda self: len([i for i in gen(self)])
	sl.__getitem__ = lambda self, index: [i for i in gen(self)][index]


def _pair_with_tuple(pr):
	pr.__getitem__ = lambda self,i: (self.first, self.second)[i]
	pr.__len__ = lambda self: 2

	pr.__from__[()] = lambda (first,second): pr(first, second)

def vector_from_list(vl):
	import warnings
	warnings.warn("The function stl.vector_from_list() is deprecated. " + \
				  "Use stl.couple() instead.")
	_vector_from_list(vl)

def build_vector(vectype, datalist):
	"""stl.build_vector(vectype, datalist) --> a vectype object
	Builds an instance of the given vector 'vectype' with the elements of
	'datalist'.
	Placement is done using std::vector<T>::push_back; element types must
	be convertible to T or an error occurs.
	"""
	vec = vectype()
	for item in datalist:
		vec.push_back(item)
	return vec

def guess_container_type(contname, conttype):
	try:
		inside = conttype.__name__[(len(contname) + len("< ")):-len(" >")]
		return robin.classByName(inside)
	except KeyError:
		return None

def couple(stltype, prefix = None, element = None):
	if prefix is None:
		prefix = stltype.__name__.split("<")[0]
	
	if prefix == "std::vector":
		_vector_from_list(stltype, element or guess_container_type(prefix, stltype))
		stltype.__to__ = reallist
	elif prefix == "std::list":
		_list_from_list(stltype, element or guess_container_type(prefix, stltype))
		stltype.__to__ = reallist
	elif prefix == "std::set":
		_set_from_list(stltype, element or guess_container_type(prefix, stltype))
		stltype.__to__ = reallist
	elif prefix == "std::pair":
		_pair_with_tuple(stltype)
	else:
		raise TypeError, "invalid STL prefix: " + prefix


# STL container template dictionary
class STLContainer(dict):
	class STLOwner:
		def __init__(self, l, c):
			import weakref
			self.l = l
			self.c = weakref.ref(c)
			
		def __del__(self):
			del self.l[:]
			self.l.extend(list(self.c()))
	
	def __setitem__(self, key, value):
		try:
			self.couple(value, truetype.get(key, key))
			dict.__setitem__(self, key, value)
		except:
			import traceback
			traceback.print_exc()

	def couple(self, conttype, elemtype):
		couple(conttype, element = elemtype)

# std::vector
vector = STLContainer()
robin.declareTemplate("std::vector", vector)

# std::list
list = STLContainer()
robin.declareTemplate("std::list", list)

# std::set
set = STLContainer()
robin.declareTemplate("std::set", set)

# generators
def gen(container):
	iter = container.begin()
	while iter != container.end():
		yield getattr(iter, "operator *")()
		getattr(iter, "operator++")()

# backward compatibility
Vector = STLContainer
Vector.VectorOwner = Vector.STLOwner
make_vector_weigher = make_container_weigher
guess_vector_type = guess_container_type

del os