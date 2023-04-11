@tool
extends Node

const SUCCESS_COLOR := Color("5fff97ff")
const ERROR_COLOR := Color("ff5f5fff")
const SELECTED_COLOR := Color.GOLD
const PREVIOUS_TILE_COLOR := Color.DARK_GRAY

const SCORED_BIT_COLOR := Color.DARK_GRAY

const ICON_BORDER_COLOR := Color.DARK_GRAY

# constants from tile_map.cpp
const NULL_TERRAIN := -99
const NULL_PRIORITY := -1
const NULL_ORIGIN := -1
const REQUIRED_PRIORITY := 999
const CENTER_BIT_ID := 99

# ICONS
const PAINTED_ICON := "CanvasItem"
