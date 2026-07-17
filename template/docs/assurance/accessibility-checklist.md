---
status: template
owner: ""
review_by: ""
---

# Accessibility Checklist (WCAG 2.2 AA)

## How to complete this document

This application targets WCAG 2.2 Level AA. Run the manual checks below against every
significant screen and flow (list them in the coverage table), record results, and fix
or ticket every failure with an owner. Repeat the checks when a flow changes materially
and before major releases. Set `status: complete` with an owner and review date once the
first full pass is recorded.

**Automated checks are evidence, not proof.** The generated `T40::Accessibility` system
check catches structural failures such as missing labels, landmarks and duplicate IDs.
Automated tools cannot judge whether the
page makes sense to a screen-reader user, whether focus order is logical, or whether an
error message actually helps. Run the automated checks in CI where wired, and treat this
manual checklist as the real evidence. Neither together constitutes formal WCAG
conformance certification.

> This template supports evidence gathering; it does not by itself provide ISO 27001,
> SOC 2, Cyber Essentials, WCAG conformance or legal compliance.

## Coverage

List the screens and flows tested. Sign-in is pre-filled because every user crosses it.

| Flow / screen | Last tested | Tested by | Result |
|---|---|---|---|
| Passwordless sign-in (request code → email → enter code) | | | |
| _Main navigation and landing screen_ | | | |
| _Each core CRUD flow_ | | | |
| Authentication error and operator empty states | | | |

## Manual checks

Run each check per flow. Record failures in the findings table with the WCAG criterion.

### 1. Keyboard

- [ ] Every interactive element is reachable and operable with the keyboard alone
      (Tab/Shift+Tab, Enter, Space, arrow keys where appropriate) (2.1.1)
- [ ] No keyboard trap: you can always tab away from any component (2.1.2)
- [ ] Focus order follows the visual and logical order of the page (2.4.3)
- [ ] Skip link or equivalent lets keyboard users bypass repeated navigation (2.4.1)
- [ ] No functionality requires dragging; a simple pointer alternative exists (2.5.7)

### 2. Focus visibility

- [ ] Every focused element shows a clearly visible focus indicator (2.4.7)
- [ ] The focused element is not entirely hidden behind sticky headers, footers or
      overlays (2.4.11)
- [ ] Focus is managed sensibly in dynamic content: moved into opened dialogs, returned
      on close, not lost on Turbo navigation or form errors

### 3. Zoom and reflow

- [ ] At 400% browser zoom (equivalent to 320px width), content reflows without
      two-dimensional scrolling and nothing is cut off or overlapped (1.4.10)
- [ ] Text can be resized to 200% without loss of content or function (1.4.4)
- [ ] Text spacing overrides (line height 1.5, paragraph 2x, letter 0.12x, word 0.16x)
      break nothing (1.4.12)

### 4. Contrast and colour

- [ ] Text contrast is at least 4.5:1 (3:1 for large text) against its background (1.4.3)
- [ ] Interactive component boundaries and states (focus rings, form field borders,
      status indicators) meet 3:1 non-text contrast (1.4.11)
- [ ] Colour is never the only means of conveying information — status badges and
      validation states carry text or icons too (1.4.1)

### 5. Screen reader

Test with at least one real screen reader (VoiceOver, NVDA or JAWS):

- [ ] Every image, icon-button and control has an accessible name that matches its
      visible label (1.1.1, 2.5.3)
- [ ] Headings and landmarks describe the page structure; navigation by heading works
      (1.3.1, 2.4.6)
- [ ] Form fields announce their label, requirement and current error (1.3.1, 3.3.2)
- [ ] Dynamic updates (flash messages, validation, Turbo frame changes) are announced —
      live regions where needed (4.1.3)
- [ ] Page titles identify each screen uniquely (2.4.2)
- [ ] Interactive elements announce their role and state (expanded, selected, checked)

### 6. Errors and forms

- [ ] Error messages identify the field in error and describe the problem in text (3.3.1)
- [ ] Errors suggest a correction where one is known (3.3.3)
- [ ] Labels or instructions are present for every input (3.3.2)
- [ ] Previously entered information is not demanded twice in one process (3.3.7)
- [ ] Sign-in requires no cognitive function test — the magic-link flow satisfies this by
      design, but verify no CAPTCHA or memorisation step has been added (3.3.8)
- [ ] Submissions with legal or financial consequences are reversible, checked or
      confirmable (3.3.4)

### 7. General

- [ ] Target size for pointer inputs is at least 24×24 CSS pixels, or spacing compensates
      (2.5.8)
- [ ] Consistent help: where help mechanisms exist they appear in the same relative place
      on every page (3.2.6)
- [ ] The page has a language attribute; content in another language is marked (3.1.1)
- [ ] Nothing flashes more than three times per second (2.3.1)
- [ ] Status of automated checks in CI: _record tool and scope, e.g. axe-core against
      system-spec pages_

## Findings

| Ref | Flow | WCAG criterion | Description | Severity | Owner | Due | Fixed |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## Statement

Once the first full pass is complete, record the outcome here and reflect it in any
public accessibility statement. Do not claim WCAG conformance on the basis of automated
checks, and do not claim it publicly without considering an independent audit.

| Field | Value |
|---|---|
| First full manual pass completed | _date_ |
| Screen reader(s) used | |
| Known limitations | |
| Public accessibility statement | _link, if published_ |
