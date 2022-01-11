#![allow(deprecated)]
#![allow(unused_imports)]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::unreadable_literal))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::let_and_return))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::new_ret_no_self))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::derive_hash_xor_eq))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::type_complexity))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::cast_ptr_alignment))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::should_implement_trait))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::missing_safety_doc))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::too_many_arguments))]
#![cfg_attr(feature = "cargo-clippy", allow(clippy::single_component_path_imports))]

extern crate bitflags;

extern crate once_cell;

extern crate gio_sys;
extern crate glib_sys;
extern crate gobject_sys;
extern crate glib;
extern crate gio;
extern crate libc;

#[cfg(feature = "futures")]
extern crate fragile;

#[cfg(feature = "futures")]
extern crate futures_core;

extern crate ffi;

pub use gio::Cancellable;

pub use glib::prelude::*;

pub use functions::*;
pub use traits::*;
