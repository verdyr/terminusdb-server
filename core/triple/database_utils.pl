:- module(database_utils,[
              system_graph_layer/2,
              database_instance/2,
              database_inference/2,
              database_schema/2,
              organization_database_name/3
          ]).

/** <module> Database Utilities
 *
 * Various database level utilities. This is a layer above the triple store
 * in terms of logic, and placed here as we want to be able to make use
 * of WOQL and other libraries without circularity.
 *
 * * * * * * * * * * * * * COPYRIGHT NOTICE  * * * * * * * * * * * * * * *
 *                                                                       *
 *  This file is part of TerminusDB.                                     *
 *                                                                       *
 *  TerminusDB is free software: you can redistribute it and/or modify   *
 *  it under the terms of the GNU General Public License as published by *
 *  the Free Software Foundation, under version 3 of the License.        *
 *                                                                       *
 *                                                                       *
 *  TerminusDB is distributed in the hope that it will be useful,        *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of       *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        *
 *  GNU General Public License for more details.                         *
 *                                                                       *
 *  You should have received a copy of the GNU General Public License    *
 *  along with TerminusDB.  If not, see <https://www.gnu.org/licenses/>. *
 *                                                                       *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
:- reexport(core(util/syntax)).

:- use_module(triplestore).
:- use_module(constants).
:- use_module(literals, [object_storage/2]).
:- use_module(casting, [idgen/3]).

:- use_module(core(util)).

:- use_module(core(query/expansions)).
:- use_module(core(query/ask)).

:- use_module(core(transaction/database)).

:- use_module(library(pcre)).

/**
 * system_graph_layer(-Graph,-Layer) is det.
 *
 * Get the document graph for Terminus as a Layer
 */
system_graph_layer(Graph,Layer) :-
    storage(Store),
    system_instance_name(Instance_Name),
    safe_open_named_graph(Store, Instance_Name, Graph),
    head(Graph, Layer).

query_default_write_descriptor(Query_Object, Write_Descriptor) :-
    convlist([Obj,Graph_Desc]>>(
                 write_obj{ descriptor : Graph_Desc }:< Obj.descriptor,
                 Graph_Desc.name = "main"
             ),
             Query_Object.instance_write_objs,
             [Write_Descriptor]).

/*
 * database_instance(Transaction_Object, Instance_Read_Write_Objects) is det.
 *
 * DEPRECATED!
 * This is a compatibility predicate that returns the list of instances associated with a transaction_object
 */
database_instance(Transaction_Object, Instances) :-
    Instances = Transaction_Object.instance_objects.

/*
 * database_inference(Transaction_Object, Inference_Read_Write_Objects) is det.
 *
 * DEPRECATED!
 * This is a compatibility predicate that returns the list of inferences associated with a transaction_object
 */
database_inference(Transaction_Object, Inferences) :-
    Inferences = Transaction_Object.inference_objects.

/*
 * database_schema(Transaction_Object, Schema_Read_Write_Objects) is det.
 *
 * DEPRECATED!
 * This is a compatibility predicate that returns the list of schemas associated with a transaction_object
 */
database_schema(Transaction_Object, Schemas) :-
    Schemas = Transaction_Object.schema_objects.

excluded_organization(Organization) :-
    re_match('\\||console|api|db|home|profile', Organization).

error_on_excluded_organization(Organization) :-
    do_or_die(\+ excluded_organization(Organization),
              error(invalid_organization_name(Organization))).

error_on_pipe(Name) :-
    do_or_die(\+ re_match('\\|', Name),
              error(ceci_n_est_pas_une_pipe(Name),_)).

/**
 * organization_database_name(User,DB,Name) is det.
 *
 */
organization_database_name(Organization,DB,Name) :-
    freeze(Organization,error_on_excluded_organization(Organization)),
    freeze(DB,error_on_pipe(DB)),
    merge_separator_split(Name,'|',[Organization,DB]).
