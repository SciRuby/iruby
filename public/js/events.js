//----------------------------------------------------------------------------
//  Copyright (C) 2008-2011  The IPython Development Team
//
//  Distributed under the terms of the BSD License.  The full license is in
//  the file COPYING, distributed as part of this software.
//----------------------------------------------------------------------------

//============================================================================
// Events
//============================================================================

// Give us an object to bind all events to. This object should be created
// before all other objects so it exists when others register event handlers.
// To trigger an event handler:
// $([IRuby.events]).trigger('event.Namespace);
// To handle it:
// $([IRuby.events]).on('event.Namespace',function () {});

var IRuby = (function (IRuby) {
    var utils = IRuby.utils;

    var Events = function () {};

    IRuby.Events = Events;
    IRuby.events = new Events();

    return IRuby;
}(IRuby));
