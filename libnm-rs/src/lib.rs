#![allow(deprecated)]

#![cfg_attr(feature = "cargo-clippy", allow(clippy::unreadable_literal))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::let_and_return))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::new_ret_no_self))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::derive_hash_xor_eq))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::type_complexity))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::cast_ptr_alignment))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::should_implement_trait))]

#[macro_use]
extern crate bitflags;

#[macro_use]
extern crate lazy_static;

extern crate gio_sys;
extern crate glib_sys;
extern crate gobject_sys;
#[macro_use]
extern crate glib;
extern crate gio;
extern crate libc;

#[cfg(feature = "futures")]
extern crate fragile;

#[cfg(feature = "futures")]
extern crate futures_core;

extern crate nm_sys;

pub use glib::Error;

mod auto;
pub use auto::functions::*;
pub use auto::*;

pub use gio::NONE_CANCELLABLE;

pub mod prelude {
    pub use glib::prelude::*;

    pub use auto::traits::*;
}

pub use prelude::*;
