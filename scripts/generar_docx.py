# Genera el informe DOCX: portada institucional, indice, encabezado y numeracion
import subprocess
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.shared import Pt, Cm, RGBColor
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

BASE = Path(__file__).resolve().parent.parent
DOC = BASE / "00-documentacion"
SALIDA = DOC / "Informe - Servidor Web Ubuntu y Nginx - G4.docx"

# 1. Cuerpo del informe desde Markdown
subprocess.run(
    ["pandoc", "informe.md", "-f", "markdown", "-t", "docx", "-o", "_cuerpo.docx"],
    cwd=DOC, check=True,
)

doc = Document(str(DOC / "_cuerpo.docx"))

# 2. Margenes y tipografia base
sec = doc.sections[0]
sec.top_margin = Cm(2.5)
sec.bottom_margin = Cm(2.5)
sec.left_margin = Cm(3.0)
sec.right_margin = Cm(2.5)

TIPOGRAFIA = "Times New Roman"

def aplicar_fuente(estilo, tam=None, negrita=None, color=None):
    try:
        st = doc.styles[estilo]
    except KeyError:
        return
    st.font.name = TIPOGRAFIA
    rpr = st.element.get_or_add_rPr()
    rf = rpr.get_or_add_rFonts()
    for attr in ("w:ascii", "w:hAnsi", "w:cs", "w:eastAsia"):
        rf.set(qn(attr), TIPOGRAFIA)
    if tam is not None:
        st.font.size = Pt(tam)
    if negrita is not None:
        st.font.bold = negrita
    if color is not None:
        st.font.color.rgb = color
    else:
        st.font.color.rgb = RGBColor(0, 0, 0)

NEGRO = RGBColor(0, 0, 0)

# Texto de parrafos y tablas: Times New Roman negro
for estilo in ("Normal", "Body Text", "First Paragraph", "Compact", "Block Text",
               "Table", "Table Grid", "Caption", "Image Caption", "Footnote Text"):
    aplicar_fuente(estilo, tam=11, color=NEGRO)

# Titulos: misma familia, en negro y en negrita
for estilo, tam in (("Heading 1", 16), ("Heading 2", 13.5), ("Heading 3", 12),
                    ("Heading 4", 11.5), ("Title", 20)):
    aplicar_fuente(estilo, tam=tam, negrita=True, color=NEGRO)

# Bloques de codigo y comandos: se mantienen monoespaciados
for estilo in ("Source Code", "Verbatim Char", "HTML Preformatted"):
    try:
        st = doc.styles[estilo]
        st.font.name = "Consolas"
        rpr = st.element.get_or_add_rPr()
        rf = rpr.get_or_add_rFonts()
        for attr in ("w:ascii", "w:hAnsi", "w:cs"):
            rf.set(qn(attr), "Consolas")
        st.font.size = Pt(9)
        st.font.color.rgb = RGBColor(0, 0, 0)
    except KeyError:
        pass

# 3. Utilidades
def nuevo_parrafo(texto="", tam=11, negrita=False, antes=0, despues=0,
                  alineacion=WD_ALIGN_PARAGRAPH.CENTER, cursiva=False):
    p = doc.add_paragraph()
    p.alignment = alineacion
    pf = p.paragraph_format
    pf.space_before = Pt(antes)
    pf.space_after = Pt(despues)
    pf.line_spacing = 1.15
    if texto:
        r = p.add_run(texto)
        r.font.size = Pt(tam)
        r.font.name = TIPOGRAFIA
        r.bold = negrita
        r.italic = cursiva
    return p

def campo(p, instruccion, texto_inicial=""):
    r = p.add_run()
    ini = OxmlElement("w:fldChar"); ini.set(qn("w:fldCharType"), "begin")
    ins = OxmlElement("w:instrText"); ins.set(qn("xml:space"), "preserve"); ins.text = instruccion
    sep = OxmlElement("w:fldChar"); sep.set(qn("w:fldCharType"), "separate")
    txt = OxmlElement("w:t"); txt.text = texto_inicial
    fin = OxmlElement("w:fldChar"); fin.set(qn("w:fldCharType"), "end")
    for el in (ini, ins, sep, txt, fin):
        r._r.append(el)

def salto_de_pagina():
    p = doc.add_paragraph()
    p.add_run().add_break(WD_BREAK.PAGE)
    return p

# 4. Portada
elementos = []
def portada(texto, tam, negrita=False, antes=0, despues=0, cursiva=False):
    elementos.append(nuevo_parrafo(texto, tam, negrita, antes, despues, cursiva=cursiva))

portada("UNIVERSIDAD NACIONAL MAYOR DE SAN MARCOS", 15.5, True, antes=16, despues=2)
portada("Fundada en 1551", 11, False, despues=22)
portada("FACULTAD DE INGENIERÍA DE SISTEMAS E INFORMÁTICA", 14, True, despues=4)
portada("ESCUELA PROFESIONAL DE INGENIERÍA DE SOFTWARE - LIMA", 12, True, despues=44)
portada("Implementación y administración de un servidor web", 17, True, despues=0)
portada("con Ubuntu Server y Nginx", 17, True, despues=8)
portada("Actividad práctica: servidor backend y persistencia", 11, False, cursiva=True, despues=34)
portada("Grupo 04", 13, True, despues=8)
portada("Estudiantes:", 11, True, despues=6)
for alumno in (
    "Joshua Nicolas Chavez Cerna",
    "Guevara Chávez Luis Rodrigo (coordinador)",
    "Montes Ramos Carol",
    "Toro Vargas Karlo Andrés",
    "Núñez Cardenas Ivan Joaquin",
):
    portada(alumno, 11, despues=1)
portada("", 11, despues=14)
portada("Docente:", 11, True, despues=2)
portada("Candela Arce, David Felix", 11, despues=12)
portada("Asignatura:", 11, True, despues=2)
portada("Taller de construcción de software web", 11, despues=26)
portada("Lima — 2026", 11, False)

# 5. Indice
elementos.append(salto_de_pagina())
p = nuevo_parrafo("Índice", 16, True, despues=12, alineacion=WD_ALIGN_PARAGRAPH.LEFT)
elementos.append(p)
p = nuevo_parrafo("", 11, alineacion=WD_ALIGN_PARAGRAPH.LEFT)
campo(p, 'TOC \\o "1-2" \\h \\z \\u', "Actualice el índice en Word: clic derecho > Actualizar campo.")
elementos.append(p)
elementos.append(salto_de_pagina())

# 6. Insertar todo al inicio del documento
for i, p in enumerate(elementos):
    doc.element.body.insert(i, p._p)

# 7. Encabezado (no en la portada) y pie con numeracion
sec.different_first_page_header_footer = True

hp = sec.header.paragraphs[0]
hp.text = ""
hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
hr = hp.add_run("UNMSM — FISI  |  Taller de construcción de software web")
hr.font.size = Pt(9)
hr.font.name = TIPOGRAFIA
hr.italic = True
hr.font.color.rgb = RGBColor(0x33, 0x33, 0x33)

fp = sec.footer.paragraphs[0]
fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = fp.add_run("Página ")
r.font.size = Pt(9)
campo(fp, "PAGE", "1")
r = fp.add_run(" de ")
r.font.size = Pt(9)
campo(fp, "NUMPAGES", "1")

# 8. Actualizar campos al abrir el documento
settings = doc.settings.element
update = OxmlElement("w:updateFields")
update.set(qn("w:val"), "true")
settings.append(update)

doc.save(str(SALIDA))
print("Documento generado:", SALIDA)
print("Tamano:", round(SALIDA.stat().st_size / 1024, 1), "KB")
