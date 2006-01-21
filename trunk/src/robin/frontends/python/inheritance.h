// -*- mode: c++; tab-width: 4; c-basic-offset: 4 -*-

/**
 * @file
 */

#ifndef ROBIN_FRONTENDS_PYTHON_INTERCEPTOR_H
#define ROBIN_FRONTENDS_PYTHON_INTERCEPTOR_H

#include <limits>
#include <Python.h>
#include "pythonobjects.h"


namespace Robin {

namespace Python {


class ClassObject;

/**
 * Enhnaces a C++ instance with Python attributes, thus allowing to extend
 * Robin classes via Python inheritance.
 */
class HybridObject : public InstanceObject
{
public:
	HybridObject(PyTypeObject *obtype);
	~HybridObject();

	static PyObject *__new_hybrid__(PyTypeObject *metaclasstype,
									PyObject *args, PyObject *kw);

	static PyObject *__init__(PyObject *self, PyObject *args);
	static PyObject *__new__(PyTypeObject *metaclasstype,
							 PyObject *args, PyObject *kw);
	static void      __del__(PyObject *object);
	static PyObject *__getattr__(PyObject *self, char *nm);
	static int       __setattr__(PyObject *self, char *nm, PyObject *value);
	
	PyObject *__getattr__(char *nm);
	int __setattr__(char *nm, PyObject *value);

public:
	PyObject *m_dict;
};


/**
 * Auxiliary class which serves as a base class in Python for classes
 * wishing to extend an abstract class.
 */
class Implementor : public PyTypeObject
{
public:
	void initialize(ClassObject *base);


	static PyObject *__new__(PyTypeObject *type, PyObject *args, PyObject* kw);

	struct Object {
		PyObject_HEAD;
		PyObject *ob_dict;
		PyObject *ob_weak;
	};

private:
	PyNumberMethods as_number;
	PySequenceMethods as_sequence;
	PyMappingMethods as_mapping;
	PyBufferProcs as_buffer;
	PyObject *name, *slots;

	ClassObject *tp_implements;
};


} // end of namespace Robin::Python

} // end of namespace Robin


#endif