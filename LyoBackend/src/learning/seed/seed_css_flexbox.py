"""Seed data for CSS Flexbox course

This script creates a complete course with:
- 3 Knowledge Components (css_basics → flexbox_fundamentals → responsive_layout)
- 8-10 Learning Objectives
- 15 Atomic Learning Objects (4 explain, 3 example, 4 exercise, 3 quiz, 1 project)
"""
import asyncio
import uuid
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from src.core.database import get_db_session
from src.learning.models import KnowledgeComponent, LearningObjective, ALO, Prerequisite


async def seed_css_flexbox():
    """Seed CSS Flexbox course data"""
    async with get_db_session() as session:
        print("🌱 Seeding CSS Flexbox course...")

        # =====================================================================
        # Knowledge Components
        # =====================================================================
        kc_basics = KnowledgeComponent(
            id=uuid.uuid4(),
            slug="css_basics",
            title="CSS Fundamentals",
            description="Core CSS concepts including selectors, properties, and the box model",
            tags=["css", "fundamentals", "web"],
        )

        kc_flexbox = KnowledgeComponent(
            id=uuid.uuid4(),
            slug="flexbox_fundamentals",
            title="Flexbox Layout System",
            description="Master CSS Flexbox for one-dimensional layouts",
            tags=["css", "flexbox", "layout"],
        )

        kc_responsive = KnowledgeComponent(
            id=uuid.uuid4(),
            slug="responsive_layout",
            title="Responsive Flexbox Layouts",
            description="Build adaptive layouts using Flexbox with media queries",
            tags=["css", "flexbox", "responsive", "advanced"],
        )

        session.add_all([kc_basics, kc_flexbox, kc_responsive])

        # Prerequisites
        prereq1 = Prerequisite(kc_id=kc_flexbox.id, prereq_kc_id=kc_basics.id)
        prereq2 = Prerequisite(kc_id=kc_responsive.id, prereq_kc_id=kc_flexbox.id)
        session.add_all([prereq1, prereq2])

        await session.flush()  # Get IDs
        print(f"✅ Created 3 Knowledge Components")

        # =====================================================================
        # Learning Objectives & ALOs
        # =====================================================================

        # --- KC 1: CSS Basics ---
        lo_basics_1 = LearningObjective(
            kc_id=kc_basics.id,
            verb="explain",
            context="CSS box model and display properties",
            difficulty=-1,
            rubric={"evidence_type": "explanation", "min_concepts": 3},
        )
        session.add(lo_basics_1)
        await session.flush()

        # ALO: Explain - CSS Box Model
        alo1 = ALO(
            lo_id=lo_basics_1.id,
            alo_type="explain",
            est_time_sec=180,
            content={
                "markdown": """# Understanding the CSS Box Model

Every element in web design is a **rectangular box**. The CSS box model describes how space is calculated around each element.

## The Four Layers

1. **Content** – Your text, images, or other media
2. **Padding** – Clear space around the content, inside the border
3. **Border** – A line around the padding (can be invisible)
4. **Margin** – Space outside the border, separating from other elements

## Key Insight

When you set `width: 300px`, you're often setting the **content** width. Padding and border are *added* on top (unless you use `box-sizing: border-box`).

## Example

```css
.box {
  width: 200px;
  padding: 20px;
  border: 2px solid black;
  margin: 10px;
}
/* Total width = 200 + 20×2 + 2×2 = 244px */
```

This foundational knowledge is critical for controlling layout precisely!
""",
                "asset_urls": []
            },
            difficulty=-1,
            tags=["css", "box-model", "basics"],
        )
        session.add(alo1)

        # ALO: Example - Box Model Demo
        alo2 = ALO(
            lo_id=lo_basics_1.id,
            alo_type="example",
            est_time_sec=120,
            content={
                "markdown": "## Box Model in Action\n\nLet's see how padding, border, and margin stack up:",
                "code": """.card {
  width: 250px;
  padding: 15px;
  border: 3px solid #3498db;
  margin: 20px;
  background: #ecf0f1;
}""",
                "language": "css",
                "asset_urls": []
            },
            difficulty=-1,
            tags=["css", "example"],
        )
        session.add(alo2)

        # --- KC 2: Flexbox Fundamentals ---
        lo_flex_1 = LearningObjective(
            kc_id=kc_flexbox.id,
            verb="apply",
            context="Flexbox container and item properties",
            difficulty=0,
            rubric={"evidence_type": "code", "required_properties": ["display", "flex-direction", "justify-content"]},
        )
        session.add(lo_flex_1)
        await session.flush()

        # ALO: Explain - What is Flexbox?
        alo3 = ALO(
            lo_id=lo_flex_1.id,
            alo_type="explain",
            est_time_sec=240,
            content={
                "markdown": """# Flexbox: The One-Dimensional Layout Champion

Flexbox (Flexible Box Layout) is a CSS layout mode designed for arranging items **in a single direction**: either as a row or a column.

## Why Flexbox?

Before Flexbox, centering elements, distributing space evenly, or making flexible layouts required hacky tricks. Flexbox makes these trivial.

## The Flexbox Model

1. **Flex Container** (`display: flex`) – The parent element
2. **Flex Items** – Direct children of the container

### Main Axis vs. Cross Axis

- **Main Axis**: Direction items flow (`flex-direction: row` → horizontal, `column` → vertical)
- **Cross Axis**: Perpendicular to main axis

## Core Container Properties

- `display: flex` – Enables Flexbox
- `flex-direction` – row | column | row-reverse | column-reverse
- `justify-content` – Aligns items along **main axis** (flex-start, center, space-between, etc.)
- `align-items` – Aligns items along **cross axis**

## Example

```css
.container {
  display: flex;
  justify-content: center; /* Horizontal centering */
  align-items: center;     /* Vertical centering */
}
```

Now let's practice!
""",
                "asset_urls": []
            },
            difficulty=0,
            tags=["flexbox", "layout"],
        )
        session.add(alo3)

        # ALO: Example - Flexbox Centering
        alo4 = ALO(
            lo_id=lo_flex_1.id,
            alo_type="example",
            est_time_sec=150,
            content={
                "markdown": "## Perfect Centering with Flexbox\n\nThe classic \"how do I center a div\" problem, solved elegantly:",
                "code": """.container {
  display: flex;
  justify-content: center; /* Center horizontally */
  align-items: center;     /* Center vertically */
  height: 100vh;
}

.box {
  width: 200px;
  height: 200px;
  background: #3498db;
  color: white;
}""",
                "language": "css",
                "asset_urls": []
            },
            difficulty=0,
            tags=["flexbox", "centering"],
        )
        session.add(alo4)

        # ALO: Exercise - Build a Flex Container
        alo5 = ALO(
            lo_id=lo_flex_1.id,
            alo_type="exercise",
            est_time_sec=300,
            content={
                "prompt": """Create a flex container with 3 items arranged horizontally with equal spacing.

**Requirements:**
- Use `display: flex`
- Distribute items with space between them
- Align items to the center vertically
""",
                "starter_code": """.container {
  /* Add your Flexbox properties here */
  height: 200px;
  border: 2px solid #ccc;
}

.item {
  width: 100px;
  height: 100px;
  background: #e74c3c;
}""",
                "language": "css",
                "hints": [
                    "Start with display: flex",
                    "Use justify-content for horizontal spacing",
                    "Use align-items for vertical alignment"
                ]
            },
            difficulty=0,
            tags=["flexbox", "exercise"],
            assessment_spec={
                "checks": [
                    {"property": "display", "value": "flex"},
                    {"property": "justify-content", "value": "space-between"},
                    {"property": "align-items", "value": "center"}
                ]
            }
        )
        session.add(alo5)

        # ALO: Quiz - Flexbox Basics
        alo6 = ALO(
            lo_id=lo_flex_1.id,
            alo_type="quiz",
            est_time_sec=90,
            content={
                "question": "Which property controls the direction of flex items in a flex container?",
                "choices": [
                    "flex-flow",
                    "flex-direction",
                    "flex-align",
                    "flex-order"
                ],
                "answer_index": 1,
                "explanation": "`flex-direction` sets the main axis direction: row (horizontal) or column (vertical)."
            },
            difficulty=0,
            tags=["flexbox", "quiz"],
        )
        session.add(alo6)

        lo_flex_2 = LearningObjective(
            kc_id=kc_flexbox.id,
            verb="apply",
            context="Flex item properties (flex-grow, flex-shrink, flex-basis)",
            difficulty=1,
            rubric={"evidence_type": "code", "required_properties": ["flex-grow", "flex-shrink", "flex-basis"]},
        )
        session.add(lo_flex_2)
        await session.flush()

        # ALO: Explain - Flex Item Properties
        alo7 = ALO(
            lo_id=lo_flex_2.id,
            alo_type="explain",
            est_time_sec=240,
            content={
                "markdown": """# Flex Item Properties: Grow, Shrink, and Basis

Flex items can **grow** to fill available space, **shrink** to fit within constraints, and have a **base size**.

## The Three Amigos

1. **flex-grow** (default: 0) – How much the item should grow relative to others
   - `flex-grow: 1` means "take available space"
   - `flex-grow: 2` means "take twice as much as siblings with flex-grow: 1"

2. **flex-shrink** (default: 1) – How much the item should shrink when space is tight
   - `flex-shrink: 0` prevents shrinking

3. **flex-basis** (default: auto) – The starting size before growing/shrinking
   - Can be a length (200px, 20%) or `auto` (use content size)

## Shorthand: `flex`

```css
.item {
  flex: 1 1 200px; /* grow shrink basis */
}
```

Or simply:

```css
.item {
  flex: 1; /* Equivalent to flex: 1 1 0% */
}
```

This is the secret to **fluid layouts**!
""",
                "asset_urls": []
            },
            difficulty=1,
            tags=["flexbox", "flex-grow", "flex-shrink"],
        )
        session.add(alo7)

        # ALO: Example - Flexible Sidebar
        alo8 = ALO(
            lo_id=lo_flex_2.id,
            alo_type="example",
            est_time_sec=150,
            content={
                "markdown": "## Flexible Sidebar Layout\n\nA common pattern: fixed sidebar, flexible main content:",
                "code": """.container {
  display: flex;
}

.sidebar {
  flex: 0 0 250px; /* Don't grow, don't shrink, fixed 250px */
  background: #34495e;
}

.main {
  flex: 1; /* Take all remaining space */
  background: #ecf0f1;
}""",
                "language": "css",
                "asset_urls": []
            },
            difficulty=1,
            tags=["flexbox", "layout-pattern"],
        )
        session.add(alo8)

        # ALO: Exercise - Build a Card Grid
        alo9 = ALO(
            lo_id=lo_flex_2.id,
            alo_type="exercise",
            est_time_sec=360,
            content={
                "prompt": """Create a responsive card layout where cards grow to fill space equally.

**Requirements:**
- All cards should have equal width (`flex: 1`)
- Add spacing between cards
- Wrap cards to new lines when needed
""",
                "starter_code": """.card-container {
  display: flex;
  /* Add wrap and spacing */
}

.card {
  /* Make cards flexible */
  min-width: 200px;
  background: #3498db;
  padding: 20px;
  color: white;
}""",
                "language": "css",
                "hints": [
                    "Use flex-wrap: wrap to allow wrapping",
                    "Set flex: 1 on cards to grow equally",
                    "Use gap or margin for spacing"
                ]
            },
            difficulty=1,
            tags=["flexbox", "exercise"],
            assessment_spec={
                "checks": [
                    {"property": "flex", "value_includes": "1"},
                    {"property": "flex-wrap", "value": "wrap"}
                ]
            }
        )
        session.add(alo9)

        # ALO: Quiz - Flex Properties
        alo10 = ALO(
            lo_id=lo_flex_2.id,
            alo_type="quiz",
            est_time_sec=90,
            content={
                "question": "If two flex items both have `flex-grow: 1`, how will available space be distributed?",
                "choices": [
                    "The first item gets all the space",
                    "The second item gets all the space",
                    "Both items share the space equally",
                    "No space is distributed"
                ],
                "answer_index": 2,
                "explanation": "When multiple items have the same `flex-grow` value, available space is distributed equally among them."
            },
            difficulty=1,
            tags=["flexbox", "quiz"],
        )
        session.add(alo10)

        # --- KC 3: Responsive Layout ---
        lo_responsive_1 = LearningObjective(
            kc_id=kc_responsive.id,
            verb="create",
            context="Responsive navigation bar using Flexbox",
            difficulty=2,
            rubric={"evidence_type": "project", "acceptance_criteria": ["mobile_stack", "desktop_row", "media_query"]},
        )
        session.add(lo_responsive_1)
        await session.flush()

        # ALO: Explain - Responsive Flexbox
        alo11 = ALO(
            lo_id=lo_responsive_1.id,
            alo_type="explain",
            est_time_sec=300,
            content={
                "markdown": """# Responsive Layouts with Flexbox

Flexbox becomes truly powerful when combined with **media queries** to create adaptive layouts.

## Mobile-First Approach

Start with a **single column** (stacked) layout for mobile:

```css
.container {
  display: flex;
  flex-direction: column; /* Stack vertically */
}
```

Then **add horizontal layout** for larger screens:

```css
@media (min-width: 768px) {
  .container {
    flex-direction: row; /* Switch to horizontal */
  }
}
```

## Common Patterns

### 1. Navigation Bar
- Mobile: Vertical stack (hamburger menu)
- Desktop: Horizontal row

### 2. Card Grid
- Mobile: 1 column
- Tablet: 2 columns
- Desktop: 3+ columns

### 3. Sidebar Layout
- Mobile: Sidebar stacks above content
- Desktop: Sidebar beside content

## Tools

- `flex-direction` changes
- `order` property to rearrange items
- `flex-wrap` for grid-like behavior

Let's build something real!
""",
                "asset_urls": []
            },
            difficulty=2,
            tags=["flexbox", "responsive", "media-queries"],
        )
        session.add(alo11)

        # ALO: Example - Responsive Navigation
        alo12 = ALO(
            lo_id=lo_responsive_1.id,
            alo_type="example",
            est_time_sec=180,
            content={
                "markdown": "## Responsive Navigation Pattern\n\nStack on mobile, row on desktop:",
                "code": """.nav {
  display: flex;
  flex-direction: column; /* Mobile: stack */
  gap: 10px;
}

.nav-item {
  padding: 15px;
  background: #3498db;
  color: white;
  text-align: center;
}

@media (min-width: 768px) {
  .nav {
    flex-direction: row; /* Desktop: horizontal */
    justify-content: space-between;
  }
}""",
                "language": "css",
                "asset_urls": []
            },
            difficulty=2,
            tags=["flexbox", "responsive", "navigation"],
        )
        session.add(alo12)

        # ALO: Quiz - Responsive Flexbox
        alo13 = ALO(
            lo_id=lo_responsive_1.id,
            alo_type="quiz",
            est_time_sec=90,
            content={
                "question": "What is the best practice for starting a responsive Flexbox layout?",
                "choices": [
                    "Start with desktop layout and add mobile styles",
                    "Start with mobile layout and add desktop styles (mobile-first)",
                    "Use only desktop styles and ignore mobile",
                    "Avoid media queries entirely"
                ],
                "answer_index": 1,
                "explanation": "Mobile-first design starts with the simplest (mobile) layout and progressively enhances for larger screens, leading to cleaner, more maintainable code."
            },
            difficulty=2,
            tags=["responsive", "quiz"],
        )
        session.add(alo13)

        # ALO: Project - Build a Responsive Dashboard
        alo14 = ALO(
            lo_id=lo_responsive_1.id,
            alo_type="project",
            est_time_sec=900,  # 15 minutes
            content={
                "brief": """# Project: Responsive Dashboard Layout

Build a dashboard that adapts seamlessly from mobile to desktop.

## Requirements

1. **Mobile (< 768px)**:
   - Single column layout
   - Header at top
   - Sidebar stacks above main content
   - Footer at bottom

2. **Desktop (≥ 768px)**:
   - Header spans full width
   - Sidebar on the left (250px fixed width)
   - Main content fills remaining space
   - Footer spans full width

3. **Bonus**:
   - Add a card grid inside main content (1 col mobile, 2 cols tablet, 3 cols desktop)
   - Use `gap` for spacing
   - Smooth transitions

## Acceptance Tests

- ✅ Mobile shows single column
- ✅ Desktop shows sidebar + main layout
- ✅ Media query at 768px breakpoint
- ✅ No horizontal scrolling on any screen size
""",
                "acceptance_tests": [
                    "Mobile layout is single column (flex-direction: column)",
                    "Desktop uses flex-direction: row for sidebar + main",
                    "Media query exists at 768px",
                    "Sidebar has fixed width on desktop",
                    "Main content uses flex: 1"
                ],
                "rubric": {
                    "mobile_layout": "Vertical stacking on small screens",
                    "desktop_layout": "Sidebar + main content on large screens",
                    "media_query": "Proper breakpoint implementation",
                    "no_overflow": "No horizontal scrolling",
                    "spacing": "Consistent gaps and padding"
                },
                "starter_files": {
                    "style.css": """/* Add your Flexbox styles here */

.dashboard {
  display: flex;
  /* Your mobile-first styles */
}

.header {
  /* Header styles */
}

.sidebar {
  /* Sidebar styles */
}

.main {
  /* Main content styles */
}

.footer {
  /* Footer styles */
}

@media (min-width: 768px) {
  /* Desktop styles */
}"""
                },
                "resources": [
                    "https://css-tricks.com/snippets/css/a-guide-to-flexbox/",
                    "https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout"
                ]
            },
            difficulty=2,
            tags=["flexbox", "responsive", "project"],
            assessment_spec={
                "auto_checks": [
                    {"test": "has_flex_container", "selector": ".dashboard"},
                    {"test": "has_media_query", "min_width": 768},
                    {"test": "flex_direction_changes", "mobile": "column", "desktop": "row"}
                ]
            }
        )
        session.add(alo14)

        # ALO: Exercise - Media Query Practice
        alo15 = ALO(
            lo_id=lo_responsive_1.id,
            alo_type="exercise",
            est_time_sec=240,
            content={
                "prompt": """Add a media query to switch a card layout from column to row.

**Requirements:**
- Mobile: Stack cards vertically
- Desktop (768px+): Display cards horizontally
- Use justify-content to space cards evenly
""",
                "starter_code": """.card-row {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.card {
  padding: 20px;
  background: #2ecc71;
  color: white;
}

/* Add your media query here */
""",
                "language": "css",
                "hints": [
                    "Start with @media (min-width: 768px)",
                    "Change flex-direction to row",
                    "Add justify-content for spacing"
                ]
            },
            difficulty=2,
            tags=["responsive", "exercise"],
            assessment_spec={
                "checks": [
                    {"has_media_query": True},
                    {"property": "flex-direction", "value": "row", "context": "media_query"}
                ]
            }
        )
        session.add(alo15)

        await session.commit()
        print(f"✅ Created {len([alo1, alo2, alo3, alo4, alo5, alo6, alo7, alo8, alo9, alo10, alo11, alo12, alo13, alo14, alo15])} ALOs")
        print("🎉 CSS Flexbox course seeded successfully!")

        return {
            "kcs": [kc_basics, kc_flexbox, kc_responsive],
            "alos_count": 15,
            "breakdown": {
                "explain": 4,
                "example": 3,
                "exercise": 4,
                "quiz": 3,
                "project": 1
            }
        }


async def main():
    """Main entry point for seeding"""
    try:
        result = await seed_css_flexbox()
        print(f"\n📊 Summary:")
        print(f"  KCs: {len(result['kcs'])}")
        print(f"  ALOs: {result['alos_count']}")
        print(f"  Breakdown: {result['breakdown']}")
    except Exception as e:
        print(f"❌ Seeding failed: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
