"""Gera o infográfico público do Scripts em APP WPF.

Uso, a partir da raiz do repositório:
    python scripts/build_infographic.py
"""

from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    Flowable,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "infografico-scripts-em-app-wpf.pdf"

NAVY = colors.HexColor("#0B2A4A")
BLUE = colors.HexColor("#126DA5")
CYAN = colors.HexColor("#00A9C7")
AMBER = colors.HexColor("#E5A32A")
PAPER = colors.HexColor("#F5F1E8")
CARD = colors.HexColor("#FFFDF8")
INK = colors.HexColor("#10243D")
MUTED = colors.HexColor("#49617A")
LINE = colors.HexColor("#C8D3DC")


def register_windows_fonts():
    """Use fontes do sistema quando disponíveis para preservar acentos no PDF."""
    candidates = {
        "PublicBody": Path(r"C:\Windows\Fonts\segoeui.ttf"),
        "PublicBold": Path(r"C:\Windows\Fonts\segoeuib.ttf"),
        "PublicTitle": Path(r"C:\Windows\Fonts\georgia.ttf"),
        "PublicCode": Path(r"C:\Windows\Fonts\consola.ttf"),
    }
    registered = {}
    for name, path in candidates.items():
        if path.exists():
            pdfmetrics.registerFont(TTFont(name, str(path)))
            registered[name] = name
    return {
        "body": registered.get("PublicBody", "Helvetica"),
        "bold": registered.get("PublicBold", "Helvetica-Bold"),
        "title": registered.get("PublicTitle", "Helvetica-Bold"),
        "code": registered.get("PublicCode", "Courier"),
    }


FONTS = register_windows_fonts()


styles = getSampleStyleSheet()
TITLE = ParagraphStyle(
    "TitlePublic", parent=styles["Title"], fontName=FONTS["title"],
    fontSize=27, leading=30, textColor=NAVY, spaceAfter=4,
)
KICKER = ParagraphStyle(
    "Kicker", parent=styles["Normal"], fontName=FONTS["bold"],
    fontSize=9.2, leading=11, textColor=BLUE, tracking=1.1,
)
DECK = ParagraphStyle(
    "Deck", parent=styles["Normal"], fontName=FONTS["body"],
    fontSize=12.2, leading=16, textColor=MUTED, spaceAfter=7,
)
H2 = ParagraphStyle(
    "H2Public", parent=styles["Heading2"], fontName=FONTS["bold"],
    fontSize=16, leading=19, textColor=NAVY, spaceBefore=3, spaceAfter=7,
)
H3 = ParagraphStyle(
    "H3Public", parent=styles["Heading3"], fontName=FONTS["bold"],
    fontSize=11.2, leading=13.5, textColor=NAVY, spaceAfter=3,
)
BODY = ParagraphStyle(
    "BodyPublic", parent=styles["BodyText"], fontName=FONTS["body"],
    fontSize=10.2, leading=13.4, textColor=INK, spaceAfter=3,
)
BODY_MUTED = ParagraphStyle(
    "BodyMuted", parent=BODY, textColor=MUTED,
)
SMALL = ParagraphStyle(
    "Small", parent=BODY, fontSize=9.3, leading=11.8, textColor=MUTED,
)
CODE = ParagraphStyle(
    "Code", parent=BODY, fontName=FONTS["code"], fontSize=9.8,
    leading=12.3, textColor=colors.HexColor("#E8F8FB"),
)
WHITE_H2 = ParagraphStyle("WhiteH2", parent=H2, textColor=colors.white)
WHITE_BODY = ParagraphStyle("WhiteBody", parent=BODY, textColor=colors.HexColor("#D9E7EE"))


class GridBackground(Flowable):
    """Faixa visual discreta inspirada em papel milimetrado de blueprint."""

    def __init__(self, width, height=16 * mm):
        super().__init__()
        self.width = width
        self.height = height

    def draw(self):
        c = self.canv
        c.saveState()
        c.setFillColor(NAVY)
        c.rect(0, 0, self.width, self.height, fill=1, stroke=0)
        c.setStrokeColor(colors.Color(1, 1, 1, alpha=0.1))
        c.setLineWidth(0.3)
        for x in range(0, int(self.width) + 1, 16):
            c.line(x, 0, x, self.height)
        for y in range(0, int(self.height) + 1, 8):
            c.line(0, y, self.width, y)
        c.restoreState()


def p(text, style=BODY):
    return Paragraph(text, style)


def card(title, body, accent=BLUE, width=57 * mm, height=None, title_style=H3):
    content = [p(title, title_style), p(body, BODY_MUTED)]
    table = Table([[content]], colWidths=[width], rowHeights=[height] if height else None)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), CARD),
        ("BOX", (0, 0), (-1, -1), 0.7, LINE),
        ("LINEABOVE", (0, 0), (-1, 0), 4, accent),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]))
    return table


def numbered_step(number, title, body):
    mark = Table([[p(number, ParagraphStyle("Num", parent=H3, textColor=colors.white, alignment=TA_LEFT))]], colWidths=[9 * mm], rowHeights=[9 * mm])
    mark.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), BLUE),
        ("ALIGN", (0, 0), (-1, -1), "CENTER"),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 3),
        ("RIGHTPADDING", (0, 0), (-1, -1), 3),
        ("TOPPADDING", (0, 0), (-1, -1), 2),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
    ]))
    copy = Table([[p(title, H3)], [p(body, BODY_MUTED)]], colWidths=[30 * mm])
    row = Table([[mark, copy]], colWidths=[10 * mm, 30 * mm])
    row.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 0),
        ("RIGHTPADDING", (0, 0), (-1, -1), 7),
        ("TOPPADDING", (0, 0), (-1, -1), 1),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    return row


def code_box(text):
    table = Table([[p(text.replace("\n", "<br/>"), CODE)]], colWidths=[172 * mm])
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#061B30")),
        ("LINEBEFORE", (0, 0), (0, -1), 4, CYAN),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    return table


def page_footer(canvas, doc):
    canvas.saveState()
    width, height = A4
    canvas.setFillColor(PAPER)
    canvas.rect(0, 0, width, 9 * mm, fill=1, stroke=0)
    canvas.setStrokeColor(LINE)
    canvas.line(19 * mm, 9 * mm, width - 19 * mm, 9 * mm)
    canvas.setFont(FONTS["body"], 8.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(19 * mm, 4.3 * mm, "Scripts em APP WPF · v1.3.0")
    canvas.drawRightString(width - 19 * mm, 4.3 * mm, f"Página {doc.page} / 2")
    canvas.restoreState()


def build():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUTPUT), pagesize=A4, leftMargin=19 * mm, rightMargin=19 * mm,
        topMargin=15 * mm, bottomMargin=13 * mm, title="Scripts em APP WPF",
        author="Lucas Forte", subject="Infográfico público da skill app",
    )
    story = []

    # Página 1 — fluxo e vantagens
    story += [GridBackground(172 * mm), Spacer(1, 6 * mm), p("SCRIPTS EM APP WPF · VISÃO GERAL", KICKER), p("Uma janela clara para um fluxo que já existe.", TITLE)]
    story += [p("Skill para transformar automações Windows existentes em apps WPF portáteis, mantendo a regra de negócio nos scripts oficiais e trazendo contexto para a operação.", DECK)]
    intro = Table([[p("A pergunta central", H3), p("O aplicativo não precisa saber mais do que o fluxo. Precisa saber o bastante para mostrar o que aconteceu, o que ficou pendente e qual é a próxima ação segura.", BODY)]], colWidths=[42 * mm, 130 * mm])
    intro.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#E4F4F6")),
        ("LINEBEFORE", (0, 0), (0, -1), 4, CYAN),
        ("BOX", (0, 0), (-1, -1), .6, LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 9),
        ("RIGHTPADDING", (0, 0), (-1, -1), 9),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 7),
    ]))
    story += [intro, Spacer(1, 6 * mm), p("Fluxo em camadas", H2)]
    flow = Table([[numbered_step("1", "Inventário transitivo", "Mapeie chamadas, entradas, saídas, dependências, efeitos, locks e arquivos protegidos."), numbered_step("2", "Contrato de resultado", "Defina run_id, métricas, exceções, estado e próxima ação em JSON UTF-8 fresco."), numbered_step("3", "Interface WPF", "Separe AppInterface, worker, parser e rodador oficial; mantenha a regra onde ela já está."), numbered_step("4", "QA observável", "Teste fixtures e a janela real: foco, teclado, rolagem, redimensionamento e estados.")]], colWidths=[43 * mm, 43 * mm, 43 * mm, 43 * mm])
    flow.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), CARD),
        ("BOX", (0, 0), (-1, -1), .7, LINE),
        ("INNERGRID", (0, 0), (-1, -1), .5, LINE),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 7),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]))
    story += [flow, Spacer(1, 6 * mm), p("O que melhora na prática", H2)]
    story += [Table([[card("Regra preservada", "O app envolve os rodadores existentes. Reescrever a regra de negócio exige pedido e escopo próprios.", BLUE, height=36 * mm), card("Resultado legível", "Contagens, cardinalidades, exceções e próxima ação aparecem antes do ruído técnico.", CYAN, height=36 * mm), card("Portabilidade", "Caminhos relativos, pré-requisitos explícitos e preparação separada ajudam a levar o app a outro computador.", AMBER, height=36 * mm)]], colWidths=[57 * mm, 57 * mm, 57 * mm], style=TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 1)]))]
    story += [Spacer(1, 4 * mm), p("Contratos neutros: <b>wpf.app.result.v1</b> para o resultado e <b>wpf.flow.inventory.v2</b> para o inventário, com caminhos locais redigidos por padrão.", SMALL), PageBreak()]

    # Página 2 — usos, segurança, exemplos e instalação
    story += [Spacer(1, 4 * mm), p("SCRIPTS EM APP WPF · APLICAÇÃO", KICKER), p("Quando usar e como manter o limite", TITLE)]
    story += [p("A abordagem é útil quando uma automação Windows já funciona em algum grau, mas sua operação precisa de uma janela portátil, uma leitura de resultado e uma trilha de decisão mais clara. O shell inicial já conecta tema, ícone e logo; $cacau só participa quando também for invocada explicitamente.", DECK), p("Situações de uso", H2)]
    situations = Table([[card("Fluxo com vários componentes", "Quando R, PowerShell, Excel, e-mail, navegador ou rede aparecem em uma cadeia transitiva que precisa ser inventariada.", BLUE, 80 * mm), card("Equipe em outro computador", "Quando pré-requisitos, caminhos e permissões precisam ser verificados sem executar o fluxo por acidente.", CYAN, 80 * mm)], [card("Resultado com pendência", "Quando encerrar o processo não significa que todos os itens foram confirmados, importados, enviados ou verificados.", AMBER, 80 * mm), card("Ação de risco", "Quando existe pagamento, envio, upload, importação ou limpeza: separar confirmação, efeito e reconciliação.", colors.HexColor("#6E4A8B"), 80 * mm)]], colWidths=[86 * mm, 86 * mm])
    situations.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 1), ("TOPPADDING", (0, 0), (-1, -1), 0), ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
    ]))
    story += [situations, Spacer(1, 3 * mm), p("Segurança visível", H2)]
    state_title = ParagraphStyle("StateTitle", parent=H3, fontSize=8.5, leading=10.2)
    states = Table([[card("SUCESSO", "Critérios obrigatórios confirmados.", BLUE, 41 * mm, height=24 * mm, title_style=state_title), card("OK_COM_PENDENCIAS", "Terminou, mas exige decisão.", AMBER, 41 * mm, height=24 * mm, title_style=state_title), card("ERRO", "Falhou sem confirmação suficiente.", colors.HexColor("#B54A3B"), 41 * mm, height=24 * mm, title_style=state_title), card("BLOQUEADO", "Não deve começar ou repetir.", colors.HexColor("#6E4A8B"), 41 * mm, height=24 * mm, title_style=state_title)]], colWidths=[43 * mm, 43 * mm, 43 * mm, 43 * mm])
    states.setStyle(TableStyle([("VALIGN", (0, 0), (-1, -1), "TOP"), ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 1)]))
    story += [states, Spacer(1, 4 * mm), p("Exemplo de instalação", H2), code_box("$skill-installer Instale a skill Scripts em APP WPF: https://github.com/cacauzuxa/scripts-em-app-wpf/tree/main/app"), Spacer(1, 3 * mm), p("Depois, invoque <b>$app</b>. A skill funciona de forma independente; se você também invocar <b>$cacau</b>, ela poderá orquestrar a implementação. Uma instalação bem-sucedida não prova homologação: ainda são necessários inventário, contrato, testes, QA em janela real e autorização para efeitos externos.", BODY)]
    story += [Spacer(1, 2 * mm), p("Limites honestos", H2), p("Não trate exit code zero, arquivo criado, processo encerrado, barra em 100% ou fixture como prova de negócio. Preserve logs técnicos sem expor credenciais ou dados locais e mantenha a repetição bloqueada quando a confirmação externa for incerta.", BODY)]

    doc.build(story, onFirstPage=page_footer, onLaterPages=page_footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
