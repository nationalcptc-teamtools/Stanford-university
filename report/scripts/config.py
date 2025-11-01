"""Configurations for various parts of the findings generation."""

from dataclasses import dataclass
from enum import Enum


# All labels used for findings
class Labels(Enum):
    #       Name     Main Color     Background Color     Sidebar Color
    C = ("Critical", "#A0210B", "rgba(140, 10, 0, 0.55)", "#C07873")
    H = ("High", "#E41111", "rgba(212, 56, 25, 0.55)", "#E79281")
    M = ("Medium", "#E27909", "rgba(229, 140, 13, 0.55)", "#E6B380")
    L = ("Low", "#F1C232", "rgba(249, 242, 92, 0.55)", "#FDF8A5")
    I = ("Informational", "#6D9EEB", "rgba(94, 207, 255, 0.55)", "#A7E6FF")  # noqa: E741

    def __init__(self, label, main_color, background_color, sidebar_color):
        self.label = label
        self.main_color = main_color
        self.background_color = background_color
        self.sidebar_color = sidebar_color

    @classmethod
    def labels(cls):
        """Returns a list of all label names."""
        return [s.label for s in cls]

    @classmethod
    def names(cls):
        """Returns a list of all member names (C, H, M, L, I)."""
        return [s.name for s in cls]

    @classmethod
    def main_colors(cls):
        """Returns a list of all main colors."""
        return [s.main_color for s in cls]

    @classmethod
    def background_colors(cls):
        """Returns a list of all background colors."""
        return [s.background_color for s in cls]


# Placeholders used in every finding document
class Placeholders(Enum):
    Label = "{Label}"
    Index = "{Index}"
    Title = "{Title}"
    Score = "{CCRI}"
    Severity = "{S}"
    ExploitationEase = "{EE}"
    BusinessImpact = "{BI}"
    Exposure = "{EX}"
    EffortToFix = "{EF}"
    AffectedHosts = "{Affected Hosts}"


# Column names used in the findings sheet
@dataclass(frozen=True)
class Columns:
    Id: str = "Id"
    Label: str = "Label (Automatic)"
    Title: str = "Title"
    Score: str = "Score (Automatic)"
    Severity: str = "Severity"
    ExploitationEase: str = "Exploitation Ease"
    BusinessImpact: str = "Business Impact"
    Exposure: str = "Exposure"
    EffortToFix: str = "Effort to Fix"
    AffectedHosts: str = "Affected Host(s)"

    @classmethod
    def all(cls) -> list[str]:
        """Return all columns"""
        return [getattr(cls, field) for field in cls.__dataclass_fields__]

    @classmethod
    def from_placeholder(cls, placeholder: Placeholders) -> "Columns | None":
        """Return the column name corresponding to the given placeholder."""
        return getattr(cls, placeholder.name, None)


# Contains the default style for the findings document
@dataclass(frozen=True)
class Style:
    Font: str = "Arial"
    # Default font size in Pt
    FontSize: str = 11
    # The width and height of the summary chart in inches
    SummaryChartWidth = 6.5
    SummaryChartHeight = 3.75


# Configuration for the chart generation
@dataclass(frozen=True)
class Chart:
    DefaultImgHash: str = "fe05eddc638096b3ee3269bd18a3f7c9aaa7297e6c9731c95f587c321b1d484d"
    QuickChartApiUrl: str = "http://localhost:8080/chart"
