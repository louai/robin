/*
 * Created on Oct 9, 2003
 */
package backend;

import java.util.Iterator;

import sourceanalysis.Aggregate;
import sourceanalysis.ContainedConnection;
import sourceanalysis.Field;
import sourceanalysis.InheritanceConnection;
import sourceanalysis.MissingInformationException;
import sourceanalysis.Namespace;
import sourceanalysis.Routine;
import sourceanalysis.Parameter;
import sourceanalysis.Scope;
import sourceanalysis.Type;

public class Traverse {


	public static interface TypeInformationVisitor
	{
		public void visit(Type typei);
	}
	
	public static interface RoutineVisitor
	{
		public void visit(Routine routine);
	}
	
	/**
	 * Go through type leaves in all members of a scope.
	 * @param starting parent scope
	 * @param visitor an object which is invoked for every type found
	 * @param intoTemplates whether or not to descend into template 
	 * declarations contained in this scope.
	 */
	public void traverse(Scope starting, TypeInformationVisitor visitor, 
		boolean intoTemplates)
	{
		// - traverse routines of scope
		for (Iterator ri = starting.routineIterator(); ri.hasNext(); ) {
			ContainedConnection connection =
				(ContainedConnection)ri.next();
			Routine routine = (Routine)connection.getContained();
			if (intoTemplates || !routine.isTemplated())
				traverse(routine, visitor);
		}
		// - traverse fields of scope
		for (Iterator fi = starting.fieldIterator(); fi.hasNext(); ) {
			ContainedConnection connection =
				(ContainedConnection)fi.next();
			Field field = (Field)connection.getContained();
			try {
				visitor.visit(field.getType());
			}
			catch (MissingInformationException e) {
				// - nahhh...
			}
		}		
	}

	/**
	 * Go through type leaves in all members of an aggregate, including 
	 * information occuring in the header (inheritance declaration).
	 * @param starting parent scope
	 * @param visitor an object which is invoked for every type found
	 * @param intoTemplates whether or not to descend into template 
	 * declarations contained in this scope.
	 */
	public void traverse(Aggregate aggregate, TypeInformationVisitor visitor, 
		boolean intoTemplates)
	{
		traverse(aggregate.getScope(), visitor, intoTemplates);
		// Also trace types occuring in inheritance
		for (Iterator bi = aggregate.baseIterator(); bi.hasNext(); ) {
			InheritanceConnection connection =
				(InheritanceConnection)bi.next();
			visitor.visit(connection.getBaseAsType());
		}
	}

	/**
	 * Go through types in a routine.
	 * These include the return types and the types of all the parameters.
	 * @param starting routine to be visited
	 * @param visitor an object which is invoked for every type found
	 */
	public void traverse(Routine starting, TypeInformationVisitor visitor)
	{
		// Visit routine's return type
		try {
			visitor.visit(starting.getReturnType());
		}
		catch (MissingInformationException e) {
			/* This type is corrupted and it's ignored */
		}
		// Visit parameters
		for (Iterator pi = starting.parameterIterator(); pi.hasNext(); ) {
			Parameter param = (Parameter)pi.next();
				
			try {
				visitor.visit(param.getType());
			}
			catch (MissingInformationException e) {
				/* This parameter is corrupted and it's ignored */
			}
		}
	}

	/**
	 * Go through type leaves in all members of a scope.
	 * @param starting parent scope
	 * @param visitor an object which is invoked for every routine found
	 */
	public void traverse(Scope starting, RoutineVisitor visitor)
	{
		for (Iterator ri = starting.routineIterator(); ri.hasNext(); ) {
			ContainedConnection connection =
				(ContainedConnection)ri.next();
			Routine routine = (Routine)connection.getContained();
			visitor.visit(routine);
		}
		for (Iterator ai = starting.aggregateIterator(); ai.hasNext(); ) {
			ContainedConnection connection =
				(ContainedConnection)ai.next();
			Aggregate aggregate = (Aggregate)connection.getContained();
			traverse(aggregate.getScope(), visitor);
		}
		for (Iterator ni = starting.namespaceIterator(); ni.hasNext(); ) {
			ContainedConnection connection =
				(ContainedConnection)ni.next();
			Namespace ns = (Namespace)connection.getContained();
			traverse(ns.getScope(), visitor);
		}
	}
	
}
