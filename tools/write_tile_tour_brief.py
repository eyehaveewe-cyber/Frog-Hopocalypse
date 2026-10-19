"""Working Channel Hideo brief; authoritative current Library text is the archive input.
The earlier review is retained in full as historical text, not silently replaced
by a stale companion design file. Pass the current Library read result JSON.
"""
import json,sys
from pathlib import Path
from docx import Document
from docx.shared import Inches,Pt,RGBColor
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
ROOT=Path(__file__).resolve().parents[1]
original=json.loads((Path(sys.argv[1]) if len(sys.argv)>1 else ROOT/'docs/design/long-hop-review-v1-text.json').read_text())
doc=Document();sec=doc.sections[0];sec.page_width=Inches(8.5);sec.page_height=Inches(11)
sec.top_margin=sec.bottom_margin=Inches(.65);sec.left_margin=sec.right_margin=Inches(.7)
style=doc.styles['Normal'];style.font.name='Calibri';style.font.size=Pt(10.5);style.paragraph_format.space_after=Pt(5);style.paragraph_format.line_spacing=1.03
for n in ['Title','Heading 1','Heading 2']:
 doc.styles[n].font.color.rgb=RGBColor(0,0,0)
footer=sec.footer.paragraphs[0];footer.alignment=2
footer.add_run('Hopán · working design | ');field=OxmlElement('w:fldSimple');field.set(qn('w:instr'),'PAGE');footer._p.append(field)
def p(text):doc.add_paragraph(text)
def h(text):doc.add_heading(text,1)
def table(headers,rows):
 t=doc.add_table(rows=1,cols=len(headers));t.style='Table Grid';t.autofit=False
 for c,v in zip(t.rows[0].cells,headers):c.text=v
 repeat=OxmlElement('w:tblHeader');t.rows[0]._tr.get_or_add_trPr().append(repeat)
 for row in rows:
  for c,v in zip(t.add_row().cells,row):c.text=str(v)
 widths=([1.8,3.7,1.6] if headers[0]=='Stage / rule' else [1.05,2.6,3.45] if headers[0]=='Rule' else [2.25,1.2,3.65]) if len(headers)==3 else [2.45,4.65]
 for col,width in zip(t.columns,widths):col.width=Inches(width)
 for row in t.rows:
  no_split=OxmlElement('w:cantSplit');row._tr.get_or_add_trPr().append(no_split)
  for c,width in zip(row.cells,widths):
   c.width=Inches(width)
   for para in c.paragraphs:
    para.paragraph_format.space_after=Pt(2);para.paragraph_format.line_spacing=1
    for run in para.runs:run.font.size=Pt(9.5);run.font.color.rgb=RGBColor(0,0,0)
   mar=OxmlElement('w:tcMar')
   for side in ['top','left','bottom','right']:
    el=OxmlElement('w:'+side);el.set(qn('w:w'),'65');el.set(qn('w:type'),'dxa');mar.append(el)
   c._tc.get_or_add_tcPr().append(mar)
 return t
def page():doc.add_page_break()
doc.add_heading('Pharaoh Frog Hopán',0);doc.add_heading('Tile Hop: five-stage tour',1)
p('Working design document · Version 2.0 · October 19, 2026 · Director: the user')
p('Current direction: make the opener more inventive, retain a reviewed second stage, add three long-hop resource stages, keep one late checkpoint per stage, and explain the action on phones. Implemented on feature/tile-hop-tours from 21f8ded. Not merged or deployed. This records implementation and test evidence; human enjoyment and final playtest approval remain open.')
h('Direction and decision history')
p('H-T01–05 are human requirements from the current request. The three-fragment threshold, Hop seed name, stage names, authored layouts and collectible-checkpoint snapshot behavior are AI-origin implementation choices within that authorized scope. Implemented does not mean that the user has endorsed their balance.')
p('The earlier version 1.0 recommendation favored an optional 10-hop prototype. The later human direction adopts per-level variety, including a dedicated 25-hop stage. That earlier restriction is superseded; its full retrieved text remains in the historical appendix. Audio, ordinary Hopán campaigns, visuals, unlock after NAHAIL and prior unpublished scenery work are retained.')
table(['Stage / rule','Spatial decision','Only checkpoint'],[
 ['1 · Big Hop Boulevard / free','Circle a moat or chain hops across a rail island. The routes meet before the final court.','(8,13)'],
 ['2 · Your Move Crossing / free + linked','Retain S-route, sideways roads and alternate vault entry; remove three flags.','(10,21)'],
 ['3 · Shardwater Sanctuary / fragments + linked','Gather three pieces per island; loop around a pond to make the visible gate usable.','(9,8)'],
 ['4 · The Seed Vault / power-up','Five switchback gates require five single-use seeds; save power by using outer banks.','(4,14)'],
 ['5 · Twenty-Five Terraces / charged + linked','Recharge through two winding forward circuits; use safe pockets to change traffic phase.','(10,22)']])
p('Design synthesis: visible destinations, purposeful collection loops and differently oriented gates respond to the requested Jak and Daxter inspiration. No copied layout or character, and no developer endorsement is implied.')
page();h('Rules, state and recovery')
p('Measured controller: one- and two-cell cardinal hops, cell 1.8 units, both 0.34 simulation seconds; normal hazard beats every 0.62 seconds. Walls/cheese block hops; the airborne middle can clear water, enemies and projectiles, while takeoff/landing remain vulnerable. Move with me advances a beat for each accepted hop.')
table(['Rule','Entry / refill','Spend / recovery'],[
 ['Free','Always available after input recovery.','No resource consumption.'],
 ['Fragments','Start empty. Three copper triangle pickups earn one reserve.','Successful long-hop takeoff spends one. Checkpoint snapshots reserve, partial pieces and collected IDs.'],
 ['Power-up','Start empty. One cyan diamond Hop seed earns one reserve.','One hop, no expiry or automatic refill. Checkpoint snapshots the same state.'],
 ['25 short hops','Start charged. Exactly 25 completed ordinary landings refill one reserve.','Blocked/idle/log carrying/menus/long hops do not recharge. Checkpoint retry refills, preserving earlier charge semantics.']])
p('AI-origin resource detail A-T02: only landings collect, only the type matching the active rule counts, and pickups remain on the ground while full. There is no inventory bank beyond one hop. An unnecessary valid jump can waste a finite resource. Retry is explicit recovery: restore the checkpoint state and make pickups gathered after that flag available again. Before a flag, restart resets all pickups.')
p('Play example: collect the third fragment on Sanctuary’s flag tile; the checkpoint captures a full reserve. Spend it on the last water gate. If the final rail kills the frog, retry returns to the flag with that reserve restored and the earlier three fragments hidden. A deliberately wasted hop can require retry; it never quietly grants extra power.')
h('Phone and keyboard contract')
p('The 166 × 64 Long hop target sits at the lower right, opposite the joystick. It continuously labels the active refill rule. Tap, then move arms the next accepted hop; Space then a direction matches it, and Shift + direction remains. Accepted hops clear arming.')
p('READY / ARMED distinguish available power and selected action. Empty states show partial fragments, FIND HOP SEED or remaining SHORT HOPS. Tapping while empty opens the rule card with live status and pauses hazards; it does not arm. Text has an outline for busy terrain. Rules have no reading timer; changed control instructions are remembered as tile-v2.')
h('Editor and data')
p('Existing Level rules adds Fragment and Power-up choices; the palette adds Hop fragment and Hop seed. Safe whole cells, no collision, two distinct silhouettes. Undo, manual Save, recovery and JSON include these objects. Map version stays 1; old readers reject the new rule values/object types. Export custom maps before reverting this feature.')
page();h('Evidence, coverage and next decisions')
p('Implemented and automated checks: 38 focused resource/progression checks; 55 existing tile checks; 35 existing rule checks. Seven hazard-active route variants complete: opener shortcut and later outer approach, two retained Crossing vault routes, Sanctuary, Seed Vault and Terraces. Eight browser checks pass with no console/page errors. Actual touch gestures gather three fragments and spend one hop; desktop Space executes a two-cell hop. Web release/debug and Windows release exports build.')
table(['Route','Hops / long hops','Recovery and result'],[
 ['Boulevard inner / outer','27 / 9; 38 / 6','One flag; complete at initial / 1.5-second later phase.'],
 ['Crossing sheltered / shortcut','70 / 8; 67 / 9','One flag; both complete with hazards active.'],
 ['Sanctuary','109 / 3','Nine fragments; one flag; complete.'],
 ['Seed Vault','71 / 5','Five seeds; one flag; complete.'],
 ['Terraces','89 / 3','Two forward recharge circuits, one safe traffic-phase detour; one flag; complete.']])
p('The route fixtures use the real 1/60-step controller with hazards active, without invincibility or teleporting. Accelerated fixed-fps simulation is not hardware FPS. Browser evidence uses Chromium/SwiftShader and Android-UA touch emulation. No physical iPhone, Safari, first-time human comprehension or enjoyment test has run.')
table(['Coverage','State / intentional boundary'],[
 ['Movement, resource lifecycle, controls, checkpoints','Implemented and tested within the five-stage tour.'],
 ['Progression and completed-set finish','Five stages; prior indices/unlock retained; final completion has no Retry or nonexistent Next.'],
 ['Scenery, audio, regular campaigns','Preserved; no redesign in this request.'],
 ['Human balance / readability','Open pilot: pickup silhouettes, resource predictions, empty taps, wasted-power recovery and one-flag frustration.'],
 ['Deployment / new systems','No site publication; no new economy, timers, stockpiling or global difficulty redesign.']])
p('Recommended next phase: play one novice and one experienced session on keyboard and a physical phone before adjusting counts. If players farm recharge or repeatedly waste pickups without understanding retry, change route/refill placement or wording based on observed behavior. Twenty-five is a requested level rule, not a measured optimum.')
page();h('Contribution register and sources')
table(['ID / origin / decision','Current state and evidence'],[
 ['H-T01 · Human · approved scope','Revise first tile stage; current request. Implemented: moat fork and central rail island.'],
 ['H-T02 · Human · approved scope','Review second, one late flag per stage. Existing second geometry/objects retained; two live routes pass.'],
 ['H-T03 · Human · approved scope','Three added stages: fragments, power-up and 25 short hops. Five-stage list and controller routes verified.'],
 ['H-T04 · Human · approved scope','Space action and clear phone button/rule feedback. Real keyboard/touch browser checks pass.'],
 ['H-T05 · Human · exploratory reference','Jak and Daxter inspiration. AI applies visible gates and collection loops; no implied approval of a copied format.'],
 ['A-T01 · AI · implementation choice','Names/layouts/three-fragment threshold. Implemented under H-T01/03; human balance acceptance pending.'],
 ['A-T02 · AI · implementation choice','One reserve, spare pickups wait, checkpoint snapshots and explicit retry recovery. Resource tests pass; human preference pending.'],
 ['A-T03 · AI · recommended next','Human pilot on resource comprehension and checkpoint frustration. Not started.'],
 ['Historical A-01/A-02 · AI · superseded in part','10-hop-only initial experiment / preserve old layouts. Later human variety request changes scope; original text retained below.']])
p('Primary project evidence: game/scripts/tile_rules.gd, level_rules.gd, main.gd and level_data.gd; game/tests/tile_tour_rules.gd, tile_tours_routes.gd and tile_demo_routes.gd; docs/TILE_TOURS_VALIDATION.json and docs/previews/tile-tours/results.json. Base SHA: 21f8ded10141a3514637c8e32236fbb8bff510a2. Revert this feature commit for rollback; preserve new-rule map exports first.')
p('Named reference: Naughty Dog, “Jak and Daxter: The Precursor Legacy 20-Year Anniversary,” December 3, 2021; Evan Wells discusses a connected, visible-accessible world. https://www.naughtydog.com/blog/jak_and_daxter_the_precursor_legacy_20_year_anniversary . Our gated-island application is AI synthesis, not a sourced design commandment.')
p('Revision 1.0: earlier scoped review at source 491ad955, exploratory resources and no gameplay changes. Revision 2.0: current human instruction authorizes implementation of per-level variety; five stages, pickup rules, recovery and controls now implemented and tested on a separate branch. No publication decision is recorded.')
page();h('Historical appendix: version 1.0')
p('The following is the complete authoritative Library text retrieved before this revision. Its old source, status and “current” statements describe that earlier review. It is retained verbatim as text; original page formatting is not reconstructed. It does not override version 2.0 above.')
for chunk in original['content']:
 if chunk.startswith('<PARSED TEXT'):continue
 for block in chunk.split('\n\n'):
  para=doc.add_paragraph(block)
  para.paragraph_format.space_after=Pt(5)
  for run in para.runs:run.font.size=Pt(9)
path=ROOT/'docs/design/Hopan-Tile-Long-Hop-Review.docx';doc.save(path)
print(path)
