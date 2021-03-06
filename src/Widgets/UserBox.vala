/*
 * Copyright (c) 2011-2017 elementary LLC. (http://launchpad.net/wingpanel)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */

public class Session.Widgets.Userbox : Gtk.ListBoxRow {
    private const string LOGGED_IN = _("Logged in");
    private const string LOGGED_OFF = _("Logged out");
    private const int ICON_SIZE = 48;

    public Act.User? user { public get; private set; }
    public bool is_guest = false;

    private Granite.Widgets.Avatar avatar;
    private Gtk.Label fullname_label;
    private Gtk.Label status_label;

    public Userbox (Act.User user) {
        this.user = user;
        build_ui ();
        connect_signals ();
        update ();
        update_state ();
    }

    public Userbox.from_data (string fullname, bool logged_in, bool is_guest = false) {
        this.is_guest = is_guest;
        this.user = null;
        build_ui ();
        fullname_label.label = "<b>" + fullname + "</b>";
        update_state ();
    }

    private void build_ui () {
        get_style_context ().add_class ("menuitem");

        var grid = new Gtk.Grid ();

        fullname_label = new Gtk.Label ("");
        fullname_label.use_markup = true;
        fullname_label.valign = Gtk.Align.END;
        fullname_label.halign = Gtk.Align.START;

        status_label = new Gtk.Label (LOGGED_OFF);
        status_label.halign = Gtk.Align.START;

        if (is_guest) {
            avatar = new Granite.Widgets.Avatar.with_default_icon (ICON_SIZE);
        } else {
            avatar = new Granite.Widgets.Avatar.from_file (user.get_icon_file (), ICON_SIZE);
        }

        avatar.margin_end = 6;

        grid.attach (avatar, 0, 0, 3, 3);
        grid.attach (fullname_label, 3, 0, 2, 1);
        grid.attach (status_label, 3, 1, 2, 1);
        this.add (grid);
    }

    // For some reason Act.User.is_logged_in () does not work
    public UserState get_user_state () {
        if (is_guest) {
            return Services.UserManager.get_guest_state ();
        }

        return Services.UserManager.get_user_state (user.get_uid ());
    }

    public bool is_logged_in () {
        var state = get_user_state ();
        return state == UserState.ONLINE || state == UserState.ACTIVE;
    }

    public void set_can_activate (bool can_activate) {
        selectable = can_activate;
        activatable = can_activate;
    }

    private void update () {
        if (is_guest) {
            return;
        }

        this.fullname_label.label = "<b>" + user.get_real_name () + "</b>";

        try {
            var pixbuf = new Gdk.Pixbuf.from_file (user.get_icon_file ());
            var size = get_style_context ().get_scale () * ICON_SIZE;
            pixbuf = pixbuf.scale_simple (size, size, Gdk.InterpType.BILINEAR);
            avatar.pixbuf = pixbuf;
        } catch (Error e) {
            avatar.show_default (ICON_SIZE);
        }
    }

    public void update_state () {
        var state = get_user_state ();
        set_can_activate (state != UserState.ACTIVE);
        if (is_logged_in ()) {
            status_label.label = LOGGED_IN;
        } else {
            status_label.label = LOGGED_OFF;
        }

        changed ();
    }

    private void connect_signals () {
        user.changed.connect (() => {
            update ();
            update_state ();
        });

        user.bind_property ("locked", this, "visible", BindingFlags.SYNC_CREATE | BindingFlags.INVERT_BOOLEAN);
        user.bind_property ("locked", this, "no-show-all", BindingFlags.SYNC_CREATE);
    }

    public override bool draw (Cairo.Context ctx) {
        if (!get_selectable ()) {
            get_style_context ().set_state (Gtk.StateFlags.NORMAL);
        }

        return base.draw (ctx);
    }    
}
