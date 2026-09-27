#Requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

[System.Windows.Forms.Application]::EnableVisualStyles()

# --- C# КЛАССЫ: DWM DARK TITLEBAR, КАРТОЧКИ И КАСТОМНЫЙ ТЕМНЫЙ РЕНДЕРЕР МЕНЮ ---
$csharpUiHelpers = @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class DarkUI {
    [DllImport("dwmapi.dll")]
    private static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    public static void UseImmersiveDarkMode(IntPtr handle) {
        try {
            int useDark = 1;
            DwmSetWindowAttribute(handle, 20, ref useDark, sizeof(int));
            DwmSetWindowAttribute(handle, 19, ref useDark, sizeof(int));
        } catch {}
    }

    public static GraphicsPath GetRoundedRect(Rectangle bounds, int radius) {
        int d = radius * 2;
        GraphicsPath path = new GraphicsPath();
        if (radius <= 0) { path.AddRectangle(bounds); return path; }
        path.AddArc(bounds.X, bounds.Y, d, d, 180, 90);
        path.AddArc(bounds.Right - d, bounds.Y, d, d, 270, 90);
        path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);
        path.AddArc(bounds.X, bounds.Bottom - d, d, d, 90, 90);
        path.CloseFigure();
        return path;
    }
}

public class KpiCardPanel : Panel {
    public string TitleText { get; set; }
    public string ValueText { get; set; }
    public string SubText   { get; set; }
    public Color AccentColor { get; set; }
    public Color SubColor    { get; set; }
    public Color NormalBg    { get; set; }
    public Color HoverBg     { get; set; }
    private bool isHovered = false;

    public KpiCardPanel() {
        this.DoubleBuffered = true;
        this.Cursor = Cursors.Hand;
    }

    protected override void OnMouseEnter(EventArgs e) {
        isHovered = true;
        this.Invalidate();
        base.OnMouseEnter(e);
    }

    protected override void OnMouseLeave(EventArgs e) {
        isHovered = false;
        this.Invalidate();
        base.OnMouseLeave(e);
    }

    protected override void OnPaint(PaintEventArgs e) {
        Graphics g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = System.Drawing.Text.TextRenderingHint.ClearTypeGridFit;

        Rectangle rect = new Rectangle(0, 0, this.Width - 1, this.Height - 1);
        using (SolidBrush bgBrush = new SolidBrush(isHovered ? HoverBg : NormalBg)) {
            g.FillRectangle(bgBrush, this.ClientRectangle);
        }

        using (SolidBrush topBar = new SolidBrush(AccentColor)) {
            g.FillRectangle(topBar, 0, 0, this.Width, 4);
        }

        using (Pen borderPen = new Pen(isHovered ? AccentColor : Color.FromArgb(45, 58, 82), 1)) {
            g.DrawRectangle(borderPen, rect);
        }

        using (Font fTitle = new Font("Segoe UI Semibold", 8.5f, FontStyle.Bold))
        using (Font fVal   = new Font("Segoe UI", 18.5f, FontStyle.Bold))
        using (Font fSub   = new Font("Segoe UI Semibold", 8.5f, FontStyle.Regular)) {
            TextRenderer.DrawText(g, TitleText, fTitle, new Point(14, 11), Color.FromArgb(148, 163, 184));
            TextRenderer.DrawText(g, ValueText, fVal,   new Point(12, 28), Color.FromArgb(241, 245, 249));
            TextRenderer.DrawText(g, SubText,   fSub,   new Point(14, 66), SubColor);
        }
    }
}

public class DarkColorTable : ProfessionalColorTable {
    public override Color ToolStripDropDownBackground { get { return Color.FromArgb(15, 23, 42); } }
    public override Color ImageMarginGradientBegin    { get { return Color.FromArgb(15, 23, 42); } }
    public override Color ImageMarginGradientMiddle   { get { return Color.FromArgb(15, 23, 42); } }
    public override Color ImageMarginGradientEnd      { get { return Color.FromArgb(15, 23, 42); } }
    public override Color MenuBorder                  { get { return Color.FromArgb(51, 65, 85); } }
    public override Color MenuItemBorder              { get { return Color.FromArgb(56, 189, 248); } }
    public override Color MenuItemSelected            { get { return Color.FromArgb(30, 58, 138); } }
    public override Color SeparatorDark               { get { return Color.FromArgb(51, 65, 85); } }
    public override Color SeparatorLight              { get { return Color.FromArgb(30, 41, 59); } }
}

public class DarkMenuRenderer : ToolStripProfessionalRenderer {
    public DarkMenuRenderer() : base(new DarkColorTable()) {}
    protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e) {
        e.TextColor = e.Item.Selected ? Color.White : Color.FromArgb(226, 232, 240);
        base.OnRenderItemText(e);
    }
}
"@
Add-Type -TypeDefinition $csharpUiHelpers -ReferencedAssemblies System.Windows.Forms, System.Drawing

# --- ЦВЕТОВАЯ ПАЛИТРА ---
$clrBgMain      = [System.Drawing.Color]::FromArgb(11, 15, 25)
$clrBgSurface   = [System.Drawing.Color]::FromArgb(17, 24, 39)
$clrBgCard      = [System.Drawing.Color]::FromArgb(30, 41, 59)
$clrBgCardHover = [System.Drawing.Color]::FromArgb(42, 56, 80)
$clrBgInput     = [System.Drawing.Color]::FromArgb(15, 23, 42)
$clrBorder      = [System.Drawing.Color]::FromArgb(51, 65, 85)
$clrTextPrimary = [System.Drawing.Color]::FromArgb(241, 245, 249)
$clrTextMuted   = [System.Drawing.Color]::FromArgb(148, 163, 184)
$clrAccentBlue  = [System.Drawing.Color]::FromArgb(56, 189, 248)
$clrAccentGreen = [System.Drawing.Color]::FromArgb(34, 197, 94)
$clrAccentAmber = [System.Drawing.Color]::FromArgb(245, 158, 11)
$clrAccentPurp  = [System.Drawing.Color]::FromArgb(168, 85, 247)
$clrAccentRed   = [System.Drawing.Color]::FromArgb(239, 68, 68)

# --- ХРАНИЛИЩЕ НАСТРОЕК (БЕЗ ХАРДКОДА ИМЕН ФЕРМ И СЕРВЕРОВ) ---
$script:configDir    = Join-Path $env:APPDATA "RDSControlCenter"
$script:settingsFile = Join-Path $script:configDir "settings.json"
$script:credFile     = Join-Path $script:configDir "ssh_cred.xml"

if (-not (Test-Path $script:configDir)) {
    New-Item -ItemType Directory -Path $script:configDir -Force | Out-Null
}

$script:candidateBrokers = @()
$script:fslogixHost      = ""

function Load-AppSettings {
    if (Test-Path $script:settingsFile) {
        try {
            $cfg = Get-Content $script:settingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($cfg.Brokers) {
                $script:candidateBrokers = @($cfg.Brokers | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
            }
            if ($cfg.FSLogixHost) {
                $script:fslogixHost = [string]$cfg.FSLogixHost.Trim()
            }
        } catch {}
    }
}

function Save-AppSettings([string[]]$brokersList, [string]$fslHost) {
    $script:candidateBrokers = @($brokersList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object { $_.Trim() })
    $script:fslogixHost      = if ($fslHost) { $fslHost.Trim() } else { "" }
    $obj = [PSCustomObject]@{
        Brokers     = $script:candidateBrokers
        FSLogixHost = $script:fslogixHost
    }
    $obj | ConvertTo-Json -Depth 3 | Set-Content -Path $script:settingsFile -Encoding UTF8
}

Load-AppSettings

# Кэш пользователей AD
$script:adCache = @{}
function Get-AdUserInfo([string]$login) {
    if ([string]::IsNullOrWhiteSpace($login)) { return @{ FullName = ""; Dept = "" } }
    $cleanLogin = $login.Split('\')[-1].ToLower()
    if ($script:adCache.ContainsKey($cleanLogin)) { return $script:adCache[$cleanLogin] }

    $info = @{ FullName = $cleanLogin; Dept = "" }
    try {
        $searcher = [adsisearcher]"(&(objectCategory=person)(objectClass=user)(sAMAccountName=$cleanLogin))"
        [void]$searcher.PropertiesToLoad.AddRange(@("displayName", "name", "department", "title"))
        $searcher.PageSize = 1
        $res = $searcher.FindOne()
        if ($res) {
            $fn = if ($res.Properties["displayName"].Count -gt 0) { [string]$res.Properties["displayName"][0] }
                   elseif ($res.Properties["name"].Count -gt 0) { [string]$res.Properties["name"][0] }
                   else { $cleanLogin }
            $dept = if ($res.Properties["department"].Count -gt 0) { [string]$res.Properties["department"][0] } else { "" }
            $title = if ($res.Properties["title"].Count -gt 0) { [string]$res.Properties["title"][0] } else { "" }
            $deptStr = if ($dept -and $title) { "$dept  •  $title" } elseif ($dept) { $dept } else { $title }
            $info = @{ FullName = $fn; Dept = $deptStr }
        }
    } catch {}
    $script:adCache[$cleanLogin] = $info
    return $info
}

# --- ГЛАВНОЕ ОКНО ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "RDS & FSLogix Control Center"
$form.Size = New-Object System.Drawing.Size(1580, 840)
$form.MinimumSize = New-Object System.Drawing.Size(1320, 640)
$form.StartPosition = "CenterScreen"
$form.BackColor = $clrBgMain
$form.ForeColor = $clrTextPrimary
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.KeyPreview = $true

$form.Add_HandleCreated({ [DarkUI]::UseImmersiveDarkMode($form.Handle) })
try {
    $exeIcon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
    if ($exeIcon) { $form.Icon = $exeIcon }
} catch {}

function New-ModernButton($text, $x, $y, $w, $h, $bgNorm, $bgHover) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
    $btn.FlatAppearance.MouseOverBackColor = $bgHover
    $btn.FlatAppearance.MouseDownBackColor = $bgNorm
    $btn.BackColor = $bgNorm
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.8, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

# --- ВЕРХНЯЯ ПАНЕЛЬ С АДАПТИВНЫМИ КАРТОЧКАМИ ---
$dashboardPanel = New-Object System.Windows.Forms.Panel
$dashboardPanel.Dock = "Top"
$dashboardPanel.Height = 108
$dashboardPanel.BackColor = $clrBgMain
$dashboardPanel.Padding = New-Object System.Windows.Forms.Padding(10, 10, 10, 6)

$kpiGrid = New-Object System.Windows.Forms.TableLayoutPanel
$kpiGrid.Dock = "Fill"
$kpiGrid.ColumnCount = 5
$kpiGrid.RowCount = 1
for ($c = 0; $c -lt 5; $c++) {
    [void]$kpiGrid.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
}
[void]$kpiGrid.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))

function New-KpiCard($title, $initVal, $subText, $accentColor) {
    $card = New-Object KpiCardPanel
    $card.Dock        = "Fill"
    $card.Margin      = New-Object System.Windows.Forms.Padding(4, 0, 4, 0)
    $card.TitleText   = $title
    $card.ValueText   = $initVal
    $card.SubText     = $subText
    $card.AccentColor = $accentColor
    $card.SubColor    = $accentColor
    $card.NormalBg    = $clrBgCard
    $card.HoverBg     = $clrBgCardHover
    return $card
}

$fslDisp = if ($script:fslogixHost) { $script:fslogixHost } else { "Не задан" }

$cardTotal   = New-KpiCard "ВСЕГО СЕССИЙ"       "—"       "▸ Показать все сессии"            $clrAccentBlue
$cardActive  = New-KpiCard "АКТИВНЫЕ СЕССИИ"    "—"       "● Работают сейчас (фильтр)"       $clrAccentGreen
$cardDisc    = New-KpiCard "ОТКЛЮЧЕННЫЕ (IDLE)" "—"       "○ Ждут переподключения"           $clrAccentAmber
$cardBrokers = New-KpiCard "УЗЛЫ И БРОКЕРЫ"     "—"       "◈ Управление узлами RDSH (Drain)" $clrAccentPurp
$cardFslogix = New-KpiCard "FSLOGIX СЕРВЕР"     $fslDisp "⚡ Управление блокировками VHDX"   $clrAccentBlue

$kpiGrid.Controls.Add($cardTotal,   0, 0)
$kpiGrid.Controls.Add($cardActive,  1, 0)
$kpiGrid.Controls.Add($cardDisc,    2, 0)
$kpiGrid.Controls.Add($cardBrokers, 3, 0)
$kpiGrid.Controls.Add($cardFslogix, 4, 0)
$dashboardPanel.Controls.Add($kpiGrid)

# --- ПАНЕЛЬ ДЕЙСТВИЙ И ФИЛЬТРОВ ---
$toolPanel = New-Object System.Windows.Forms.Panel
$toolPanel.Dock = "Top"
$toolPanel.Height = 94
$toolPanel.BackColor = $clrBgSurface

# Ряд 1: Кнопки управления
$btnRefresh       = New-ModernButton "⟳ Обновить (F5)"            14   10 120 34 ([System.Drawing.Color]::FromArgb(37, 99, 235))  ([System.Drawing.Color]::FromArgb(59, 130, 246))
$btnShadowControl = New-ModernButton "▣ Управление (Без запроса)" 140  10 185 34 ([System.Drawing.Color]::FromArgb(5, 150, 105))  ([System.Drawing.Color]::FromArgb(16, 185, 129))
$btnShadowView    = New-ModernButton "◉ Наблюдение (Без запроса)" 331  10 185 34 ([System.Drawing.Color]::FromArgb(13, 148, 136)) ([System.Drawing.Color]::FromArgb(20, 184, 166))
$btnNodes         = New-ModernButton "◈ Узлы RDSH (Drain)"        522  10 155 34 ([System.Drawing.Color]::FromArgb(30, 64, 175))  ([System.Drawing.Color]::FromArgb(59, 130, 246))
$btnFSLogix       = New-ModernButton "⚡ Профили FSLogix"          683  10 150 34 ([System.Drawing.Color]::FromArgb(126, 34, 206)) ([System.Drawing.Color]::FromArgb(147, 51, 234))
$btnProcesses     = New-ModernButton "⚙ Процессы"                 839  10 110 34 ([System.Drawing.Color]::FromArgb(67, 56, 202))  ([System.Drawing.Color]::FromArgb(99, 102, 241))
$btnMsg           = New-ModernButton "✉ Сообщение"                955  10 110 34 ([System.Drawing.Color]::FromArgb(3, 105, 161))  ([System.Drawing.Color]::FromArgb(14, 165, 233))
$btnDisconnect    = New-ModernButton "⏸ Отключить"                1071 10 105 34 ([System.Drawing.Color]::FromArgb(180, 83, 9))   ([System.Drawing.Color]::FromArgb(217, 119, 6))
$btnLogoff        = New-ModernButton "✖ Сбросить"                 1182 10 105 34 ([System.Drawing.Color]::FromArgb(185, 28, 28))  ([System.Drawing.Color]::FromArgb(239, 68, 68))
$btnExport        = New-ModernButton "⤓ CSV"                      1293 10 75  34 ([System.Drawing.Color]::FromArgb(51, 65, 85))   ([System.Drawing.Color]::FromArgb(71, 85, 105))
$btnSettings      = New-ModernButton "⚙ Настройки"                1374 10 120 34 ([System.Drawing.Color]::FromArgb(30, 41, 59))   ([System.Drawing.Color]::FromArgb(71, 85, 105))

# Ряд 2: Фильтры и поиск
$lblBroker = New-Object System.Windows.Forms.Label
$lblBroker.Text = "ФЕРМА:"
$lblBroker.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)
$lblBroker.ForeColor = $clrTextMuted
$lblBroker.Location = New-Object System.Drawing.Point(14, 58)
$lblBroker.AutoSize = $true

$cbBrokers = New-Object System.Windows.Forms.ComboBox
$cbBrokers.DropDownStyle = "DropDownList"
$cbBrokers.FlatStyle = "Flat"
$cbBrokers.BackColor = $clrBgCard
$cbBrokers.ForeColor = $clrTextPrimary
$cbBrokers.Location = New-Object System.Drawing.Point(70, 54)
$cbBrokers.Size = New-Object System.Drawing.Size(210, 26)

function Update-BrokerComboList {
    $cbBrokers.Items.Clear()
    [void]$cbBrokers.Items.Add("Все брокеры")
    foreach ($b in $script:candidateBrokers) {
        [void]$cbBrokers.Items.Add($b.Split('.')[0])
    }
    $cbBrokers.SelectedIndex = 0
}
Update-BrokerComboList

$lblState = New-Object System.Windows.Forms.Label
$lblState.Text = "СТАТУС:"
$lblState.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)
$lblState.ForeColor = $clrTextMuted
$lblState.Location = New-Object System.Drawing.Point(295, 58)
$lblState.AutoSize = $true

$cbState = New-Object System.Windows.Forms.ComboBox
$cbState.DropDownStyle = "DropDownList"
$cbState.FlatStyle = "Flat"
$cbState.BackColor = $clrBgCard
$cbState.ForeColor = $clrTextPrimary
$cbState.Location = New-Object System.Drawing.Point(355, 54)
$cbState.Size = New-Object System.Drawing.Size(165, 26)
[void]$cbState.Items.AddRange(@("Все сессии", "Только Активные", "Только Отключенные"))
$cbState.SelectedIndex = 0

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text = "ПОИСК:"
$lblSearch.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)
$lblSearch.ForeColor = $clrTextMuted
$lblSearch.Location = New-Object System.Drawing.Point(535, 58)
$lblSearch.AutoSize = $true

$searchBoxBorder = New-Object System.Windows.Forms.Panel
$searchBoxBorder.Location = New-Object System.Drawing.Point(592, 53)
$searchBoxBorder.Size = New-Object System.Drawing.Size(310, 27)
$searchBoxBorder.BackColor = $clrAccentBlue
$searchBoxBorder.Padding = New-Object System.Windows.Forms.Padding(1)

$searchInner = New-Object System.Windows.Forms.Panel
$searchInner.Dock = "Fill"
$searchInner.BackColor = $clrBgInput

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.BorderStyle = "None"
$txtSearch.BackColor = $clrBgInput
$txtSearch.ForeColor = $clrTextPrimary
$txtSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$txtSearch.Location = New-Object System.Drawing.Point(8, 4)
$txtSearch.Size = New-Object System.Drawing.Size(268, 20)

$btnClearSearch = New-Object System.Windows.Forms.Label
$btnClearSearch.Text = "✕"
$btnClearSearch.ForeColor = $clrTextMuted
$btnClearSearch.BackColor = $clrBgInput
$btnClearSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$btnClearSearch.Location = New-Object System.Drawing.Point(284, 4)
$btnClearSearch.Size = New-Object System.Drawing.Size(20, 18)
$btnClearSearch.Cursor = [System.Windows.Forms.Cursors]::Hand

$searchInner.Controls.AddRange(@($txtSearch, $btnClearSearch))
$searchBoxBorder.Controls.Add($searchInner)

$chkAutoRefresh = New-Object System.Windows.Forms.CheckBox
$chkAutoRefresh.Text = "Автообновление (30 сек)"
$chkAutoRefresh.ForeColor = $clrTextPrimary
$chkAutoRefresh.Location = New-Object System.Drawing.Point(920, 56)
$chkAutoRefresh.AutoSize = $true

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "★ Двойной клик по строке — мгновенный теневой вход"
$lblHint.ForeColor = $clrTextMuted
$lblHint.Location = New-Object System.Drawing.Point(1115, 58)
$lblHint.AutoSize = $true

$toolPanel.Controls.AddRange(@(
    $btnRefresh, $btnShadowControl, $btnShadowView, $btnNodes, $btnFSLogix, $btnProcesses, $btnMsg, $btnDisconnect, $btnLogoff, $btnExport, $btnSettings,
    $lblBroker, $cbBrokers, $lblState, $cbState, $lblSearch, $searchBoxBorder, $chkAutoRefresh, $lblHint
))

# --- НИЖНИЙ СТАТУС-БАР ---
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Dock = "Bottom"
$statusPanel.Height = 30
$statusPanel.BackColor = $clrBgSurface

$progressBar = New-Object System.Windows.Forms.Panel
$progressBar.Location = New-Object System.Drawing.Point(0, 0)
$progressBar.Size = New-Object System.Drawing.Size(0, 2)
$progressBar.BackColor = $clrAccentBlue

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Готов к работе"
$lblStatus.ForeColor = $clrTextMuted
$lblStatus.Location = New-Object System.Drawing.Point(14, 7)
$lblStatus.AutoSize = $true

$statusPanel.Controls.AddRange(@($progressBar, $lblStatus))

# --- ТАБЛИЦА СЕССИЙ ---
$gridPanel = New-Object System.Windows.Forms.Panel
$gridPanel.Dock = "Fill"
$gridPanel.Padding = New-Object System.Windows.Forms.Padding(14, 8, 14, 8)
$gridPanel.BackColor = $clrBgMain

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Dock = "Fill"
$grid.AutoSizeColumnsMode = "Fill"
$grid.SelectionMode = "FullRowSelect"
$grid.MultiSelect = $true
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToOrderColumns = $true
$grid.RowHeadersVisible = $false
$grid.BackgroundColor = $clrBgSurface
$grid.BorderStyle = "None"
$grid.CellBorderStyle = "SingleHorizontal"
$grid.GridColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$grid.EnableHeadersVisualStyles = $false
$grid.ColumnHeadersBorderStyle = "None"
$grid.ColumnHeadersHeight = 40
$grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$grid.ColumnHeadersDefaultCellStyle.ForeColor = $clrAccentBlue
$grid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5, [System.Drawing.FontStyle]::Bold)
$grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$grid.RowTemplate.Height = 34
$grid.DefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(15, 23, 42)
$grid.DefaultCellStyle.ForeColor = $clrTextPrimary
$grid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)
$grid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
$grid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(19, 28, 49)

$doubleBufferProp = $grid.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance,NonPublic")
if ($doubleBufferProp) { $doubleBufferProp.SetValue($grid, $true, $null) }

$gridPanel.Controls.Add($grid)

# --- КОНТЕКСТНОЕ МЕНЮ (ПКМ) ---
$ctxMenu = New-Object System.Windows.Forms.ContextMenuStrip
$ctxMenu.Renderer = New-Object DarkMenuRenderer
$ctxMenu.Font = New-Object System.Drawing.Font("Segoe UI", 9.5)
$miShadowCtrl = $ctxMenu.Items.Add("▣  Теневой доступ: Управление (без запроса)")
$miShadowView = $ctxMenu.Items.Add("◉  Теневой доступ: Наблюдение (без запроса)")
[void]$ctxMenu.Items.Add("-")
$miNodesMgr   = $ctxMenu.Items.Add("◈  Управление узлами сеансов RDSH (Drain Mode)...")
$miNodeAllow  = $ctxMenu.Items.Add("✔  Разрешить вход на этот сервер RDSH (Yes)")
$miNodeDrain  = $ctxMenu.Items.Add("⏸  Запретить новые входы на этот сервер RDSH (Drain)")
[void]$ctxMenu.Items.Add("-")
$miFSLogix    = $ctxMenu.Items.Add("⚡  Разблокировать VHDX на сервере FSLogix...")
$miProcesses  = $ctxMenu.Items.Add("⚙  Диспетчер процессов пользователя...")
$miSendMsg    = $ctxMenu.Items.Add("✉  Отправить сообщение...")
[void]$ctxMenu.Items.Add("-")
$miCopyUser   = $ctxMenu.Items.Add("◈  Скопировать логин и ФИО")
$miOpenC      = $ctxMenu.Items.Add("▸  Открыть диск C`$ на сервере RDSH")
[void]$ctxMenu.Items.Add("-")
$miDisconnect = $ctxMenu.Items.Add("⏸  Отключить сеанс (Disconnect)")
$miLogoff     = $ctxMenu.Items.Add("✖  Сбросить сеанс (Logoff)")
$grid.ContextMenuStrip = $ctxMenu

$form.Controls.AddRange(@($gridPanel, $toolPanel, $dashboardPanel, $statusPanel))

$script:table = $null
$script:isLoading = $false
$script:runspacePool = $null
$script:jobs = @()
$script:rdModuleLoaded = $false
$script:timer = New-Object System.Windows.Forms.Timer
$script:timer.Interval = 90

$script:autoTimer = New-Object System.Windows.Forms.Timer
$script:autoTimer.Interval = 30000

function Ensure-RDModule {
    if (-not $script:rdModuleLoaded) {
        Import-Module RemoteDesktop -ErrorAction SilentlyContinue
        $script:rdModuleLoaded = $true
    }
}

# --- ОКНО НАСТРОЕК ИНФРАСТРУКТУРЫ (СПИСОК ФЕРМ И СЕРВЕР FSLOGIX) ---
$ShowSettingsDialog = {
    $sForm = New-Object System.Windows.Forms.Form
    $sForm.Text = "Настройки инфраструктуры — Брокеры RDS и Сервер FSLogix"
    $sForm.Size = New-Object System.Drawing.Size(620, 490)
    $sForm.StartPosition = "CenterParent"
    $sForm.FormBorderStyle = "FixedDialog"
    $sForm.MaximizeBox = $false; $sForm.MinimizeBox = $false
    $sForm.BackColor = $clrBgMain
    $sForm.ForeColor = $clrTextPrimary
    $sForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $sForm.Add_HandleCreated({ [DarkUI]::UseImmersiveDarkMode($sForm.Handle) })

    $lblBTitle = New-Object System.Windows.Forms.Label
    $lblBTitle.Text = "Список серверов RD Connection Broker (по одному FQDN или IP на строку):"
    $lblBTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5, [System.Drawing.FontStyle]::Bold)
    $lblBTitle.ForeColor = $clrAccentBlue
    $lblBTitle.Location = New-Object System.Drawing.Point(20, 18); $lblBTitle.AutoSize = $true

    $txtBrokersList = New-Object System.Windows.Forms.TextBox
    $txtBrokersList.Multiline = $true
    $txtBrokersList.ScrollBars = "Vertical"
    $txtBrokersList.BackColor = $clrBgCard
    $txtBrokersList.ForeColor = $clrTextPrimary
    $txtBrokersList.BorderStyle = "FixedSingle"
    $txtBrokersList.Font = New-Object System.Drawing.Font("Consolas", 10)
    $txtBrokersList.Location = New-Object System.Drawing.Point(20, 44)
    $txtBrokersList.Size = New-Object System.Drawing.Size(560, 185)
    $txtBrokersList.Text = ($script:candidateBrokers -join "`r`n")

    $btnAdDiscover = New-ModernButton "🔍 Найти серверы RDS/RDCB в Active Directory" 20 238 330 32 ([System.Drawing.Color]::FromArgb(30, 64, 175)) ([System.Drawing.Color]::FromArgb(59, 130, 246))
    $btnClearList  = New-ModernButton "Очистить список"                              360 238 140 32 ([System.Drawing.Color]::FromArgb(51, 65, 85))  ([System.Drawing.Color]::FromArgb(71, 85, 105))

    $lblFTitle = New-Object System.Windows.Forms.Label
    $lblFTitle.Text = "Сервер хранения контейнеров профилей FSLogix (Ubuntu / Samba SSH — IP или FQDN):"
    $lblFTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.5, [System.Drawing.FontStyle]::Bold)
    $lblFTitle.ForeColor = $clrAccentBlue
    $lblFTitle.Location = New-Object System.Drawing.Point(20, 290); $lblFTitle.AutoSize = $true

    $txtFslServer = New-Object System.Windows.Forms.TextBox
    $txtFslServer.BackColor = $clrBgCard
    $txtFslServer.ForeColor = $clrTextPrimary
    $txtFslServer.BorderStyle = "FixedSingle"
    $txtFslServer.Font = New-Object System.Drawing.Font("Consolas", 10.5)
    $txtFslServer.Location = New-Object System.Drawing.Point(20, 316)
    $txtFslServer.Size = New-Object System.Drawing.Size(560, 28)
    $txtFslServer.Text = $script:fslogixHost

    $lblNote = New-Object System.Windows.Forms.Label
    $lblNote.Text = "Настройки сохраняются локально в %APPDATA%\RDSControlCenter\settings.json"
    $lblNote.ForeColor = $clrTextMuted
    $lblNote.Location = New-Object System.Drawing.Point(20, 355); $lblNote.AutoSize = $true

    $btnSaveCfg   = New-ModernButton "✔ Сохранить и опросить фермы" 20  392 260 36 ([System.Drawing.Color]::FromArgb(5, 150, 105)) ([System.Drawing.Color]::FromArgb(16, 185, 129))
    $btnCancelCfg = New-ModernButton "Отмена"                       295 392 120 36 ([System.Drawing.Color]::FromArgb(51, 65, 85))  ([System.Drawing.Color]::FromArgb(71, 85, 105))

    # Автопоиск брокеров в текущем домене AD
    $btnAdDiscover.Add_Click({
        try {
            $s = [adsisearcher]"(&(objectCategory=computer)(|(name=*RDCB*)(name=*RDS*)(name=*BROKER*)(servicePrincipalName=*TERMSRV*)))"
            [void]$s.PropertiesToLoad.Add("dNSHostName")
            $s.PageSize = 200
            $found = @()
            foreach ($r in $s.FindAll()) {
                if ($r.Properties["dNSHostName"].Count -gt 0) {
                    $h = [string]$r.Properties["dNSHostName"][0]
                    if ($h -match "RDCB|BROKER") { $found += $h }
                }
            }
            if ($found.Count -eq 0) {
                foreach ($r in $s.FindAll()) {
                    if ($r.Properties["dNSHostName"].Count -gt 0) {
                        $found += [string]$r.Properties["dNSHostName"][0]
                    }
                }
            }
            $found = @($found | Select-Object -Unique | Sort-Object)
            if ($found.Count -gt 0) {
                $existing = @($txtBrokersList.Text -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
                $merged = @($existing + $found | Select-Object -Unique)
                $txtBrokersList.Text = ($merged -join "`r`n")
                [System.Windows.Forms.MessageBox]::Show("Найдено серверов в AD: $($found.Count)", "Поиск в Active Directory", "OK", "Information")
            } else {
                [System.Windows.Forms.MessageBox]::Show("Серверы с именем RDCB/Broker не найдены автоматически. Введите FQDN или IP брокеров вручную.", "Поиск в AD", "OK", "Information")
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Ошибка обращения к AD: $($_.Exception.Message)", "Ошибка", "OK", "Warning")
        }
    })

    $btnClearList.Add_Click({ $txtBrokersList.Text = "" })

    $btnSaveCfg.Add_Click({
        $lines = @($txtBrokersList.Text -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Save-AppSettings $lines $txtFslServer.Text
        Update-BrokerComboList
        $cardFslogix.ValueText = if ($script:fslogixHost) { $script:fslogixHost } else { "Не задан" }
        $cardFslogix.Invalidate()
        $sForm.DialogResult = "OK"
        $sForm.Close()
        & $StartLoadSessions
    })

    $btnCancelCfg.Add_Click({ $sForm.Close() })

    $sForm.Controls.AddRange(@($lblBTitle, $txtBrokersList, $btnAdDiscover, $btnClearList, $lblFTitle, $txtFslServer, $lblNote, $btnSaveCfg, $btnCancelCfg))
    [void]$sForm.ShowDialog($form)
}

# --- ФУНКЦИЯ ИЗМЕНЕНИЯ СТАТУСА ПОДКЛЮЧЕНИЙ К УЗЛУ RDSH ---
function Set-RdsNodeDrainState([string]$brokerFqdn, [string]$rdshFqdn, [string]$newState) {
    Ensure-RDModule
    $applied = $false
    try {
        Set-RDSessionHost -SessionHost $rdshFqdn -NewConnectionAllowed $newState -ConnectionBroker $brokerFqdn -ErrorAction Stop
        $applied = $true
    } catch {
        try {
            $drainVal = switch ($newState) {
                "Yes"            { 0 }
                "NotUntilReboot" { 1 }
                "No"             { 2 }
                default          { 0 }
            }
            $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $rdshFqdn)
            $key = $reg.CreateSubKey("SYSTEM\CurrentControlSet\Control\Terminal Server")
            $key.SetValue("TSServerDrainMode", $drainVal, [Microsoft.Win32.RegistryValueKind]::DWord)
            $key.Close()

            $wmi = Get-WmiObject -Namespace "root\CIMV2\TerminalServices" -Class "Win32_TerminalServiceSetting" -ComputerName $rdshFqdn -Authentication PacketPrivacy -ErrorAction SilentlyContinue
            if ($wmi) {
                $wmi.SessionBrokerDrainMode = $drainVal
                [void]$wmi.Put()
            }
            $reg.Close()
            $applied = $true
        } catch {}
    }
    return $applied
}

# --- МОДУЛЬ УПРАВЛЕНИЯ УЗЛАМИ СЕАНСОВ RDSH (DRAIN MODE) ---
$ShowNodesManager = {
    if ($script:candidateBrokers.Count -eq 0) {
        & $ShowSettingsDialog
        return
    }

    $nForm = New-Object System.Windows.Forms.Form
    $nForm.Text = "Управление узлами сеансов RDSH (Разрешение / Запрет новых подключений)"
    $nForm.Size = New-Object System.Drawing.Size(1180, 600)
    $nForm.StartPosition = "CenterParent"
    $nForm.BackColor = $clrBgMain
    $nForm.ForeColor = $clrTextPrimary
    $nForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $nForm.Add_HandleCreated({ [DarkUI]::UseImmersiveDarkMode($nForm.Handle) })

    $nTop = New-Object System.Windows.Forms.Panel
    $nTop.Dock = "Top"; $nTop.Height = 58
    $nTop.BackColor = $clrBgSurface

    $lblNFarm = New-Object System.Windows.Forms.Label
    $lblNFarm.Text = "ФЕРМА:"
    $lblNFarm.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)
    $lblNFarm.ForeColor = $clrTextMuted
    $lblNFarm.Location = New-Object System.Drawing.Point(16, 19); $lblNFarm.AutoSize = $true

    $cbNFarm = New-Object System.Windows.Forms.ComboBox
    $cbNFarm.DropDownStyle = "DropDownList"
    $cbNFarm.FlatStyle = "Flat"
    $cbNFarm.BackColor = $clrBgCard; $cbNFarm.ForeColor = $clrTextPrimary
    $cbNFarm.Location = New-Object System.Drawing.Point(75, 15); $cbNFarm.Size = New-Object System.Drawing.Size(165, 26)
    [void]$cbNFarm.Items.Add("Все фермы")
    foreach ($b in $script:candidateBrokers) { [void]$cbNFarm.Items.Add($b.Split('.')[0]) }
    $cbNFarm.SelectedIndex = if ($cbBrokers.SelectedIndex -lt $cbNFarm.Items.Count) { $cbBrokers.SelectedIndex } else { 0 }

    $btnNRefresh = New-ModernButton "⟳ Обновить узлы"                  255 12 150 34 ([System.Drawing.Color]::FromArgb(37, 99, 235))  ([System.Drawing.Color]::FromArgb(59, 130, 246))
    $btnNAllow   = New-ModernButton "✔ Разрешить вход (Yes)"           415 12 200 34 ([System.Drawing.Color]::FromArgb(5, 150, 105))  ([System.Drawing.Color]::FromArgb(16, 185, 129))
    $btnNReboot  = New-ModernButton "⏸ Запретить до ребута (Drain)"    623 12 245 34 ([System.Drawing.Color]::FromArgb(180, 83, 9))   ([System.Drawing.Color]::FromArgb(217, 119, 6))
    $btnNDeny    = New-ModernButton "✖ Полный запрет входа (No)"       876 12 235 34 ([System.Drawing.Color]::FromArgb(185, 28, 28))  ([System.Drawing.Color]::FromArgb(239, 68, 68))

    $nTop.Controls.AddRange(@($lblNFarm, $cbNFarm, $btnNRefresh, $btnNAllow, $btnNReboot, $btnNDeny))

    $nStatusPanel = New-Object System.Windows.Forms.Panel
    $nStatusPanel.Dock = "Bottom"; $nStatusPanel.Height = 32
    $nStatusPanel.BackColor = $clrBgSurface

    $lblNStatus = New-Object System.Windows.Forms.Label
    $lblNStatus.Text = "Опрос брокеров..."
    $lblNStatus.ForeColor = $clrAccentBlue
    $lblNStatus.Location = New-Object System.Drawing.Point(16, 7); $lblNStatus.AutoSize = $true
    $nStatusPanel.Controls.Add($lblNStatus)

    $nGrid = New-Object System.Windows.Forms.DataGridView
    $nGrid.Dock = "Fill"; $nGrid.AutoSizeColumnsMode = "Fill"
    $nGrid.SelectionMode = "FullRowSelect"; $nGrid.MultiSelect = $true
    $nGrid.ReadOnly = $true; $nGrid.AllowUserToAddRows = $false
    $nGrid.RowHeadersVisible = $false
    $nGrid.BackgroundColor = $clrBgMain
    $nGrid.BorderStyle = "None"
    $nGrid.CellBorderStyle = "SingleHorizontal"
    $nGrid.GridColor = $clrBgCard
    $nGrid.EnableHeadersVisualStyles = $false
    $nGrid.ColumnHeadersBorderStyle = "None"
    $nGrid.ColumnHeadersHeight = 38
    $nGrid.ColumnHeadersDefaultCellStyle.BackColor = $clrBgCard
    $nGrid.ColumnHeadersDefaultCellStyle.ForeColor = $clrAccentBlue
    $nGrid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9.2, [System.Drawing.FontStyle]::Bold)
    $nGrid.DefaultCellStyle.BackColor = $clrBgSurface
    $nGrid.DefaultCellStyle.ForeColor = $clrTextPrimary
    $nGrid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)
    $nGrid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $nGrid.AlternatingRowsDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(19, 28, 49)
    $nGrid.RowTemplate.Height = 34

    $dbProp = $nGrid.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance,NonPublic")
    if ($dbProp) { $dbProp.SetValue($nGrid, $true, $null) }

    $nGrid.Add_CellPainting({
        param($s, $e)
        if ($e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0) { return }
        if ($nGrid.Columns[$e.ColumnIndex].Name -eq "Новые подключения") {
            $e.PaintBackground($e.ClipBounds, $true)
            $val = [string]$e.Value
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

            $pillW = [Math]::Min(220, $e.CellBounds.Width - 12)
            $pillH = 22
            $pillX = $e.CellBounds.X + 6
            $pillY = $e.CellBounds.Y + [int](($e.CellBounds.Height - $pillH) / 2)
            $rect  = New-Object System.Drawing.Rectangle($pillX, $pillY, $pillW, $pillH)

            if ($val -match "Разрешены") {
                $bgB  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 83, 45))
                $penB = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(34, 197, 94), 1)
                $txtC = [System.Drawing.Color]::FromArgb(134, 239, 172)
            } elseif ($val -match "До перезагрузки") {
                $bgB  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, 53, 15))
                $penB = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(245, 158, 11), 1)
                $txtC = [System.Drawing.Color]::FromArgb(253, 230, 138)
            } else {
                $bgB  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(127, 29, 29))
                $penB = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(239, 68, 68), 1)
                $txtC = [System.Drawing.Color]::FromArgb(254, 202, 202)
            }

            $path = [DarkUI]::GetRoundedRect($rect, 10)
            $g.FillPath($bgB, $path)
            $g.DrawPath($penB, $path)
            [System.Windows.Forms.TextRenderer]::DrawText(
                $g, $val,
                (New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)),
                $rect, $txtC,
                [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter
            )
            $path.Dispose(); $bgB.Dispose(); $penB.Dispose()
            $e.Handled = $true
        }
    })

    $nForm.Controls.AddRange(@($nGrid, $nTop, $nStatusPanel))
    $script:nodesTable = $null

    $FilterNodes = {
        if (-not $script:nodesTable) { return }
        if ($cbNFarm.SelectedIndex -gt 0) {
            $selF = $cbNFarm.SelectedItem.ToString()
            $script:nodesTable.DefaultView.RowFilter = "Ферма = '$selF'"
        } else {
            $script:nodesTable.DefaultView.RowFilter = ""
        }
        $lblNStatus.Text = "Показано узлов RDSH: $($script:nodesTable.DefaultView.Count) из $($script:nodesTable.Rows.Count)"
    }

    $LoadNodes = {
        $lblNStatus.Text = "Параллельный опрос узлов сеансов RDSH по всем фермам..."
        $btnNRefresh.Enabled = $false
        $nForm.Refresh()

        $nodeWorker = {
            param([string]$brokerHost)
            $list = @()
            $tcp = New-Object System.Net.Sockets.TcpClient
            try {
                $ar = $tcp.BeginConnect($brokerHost, 135, $null, $null)
                if (-not $ar.AsyncWaitHandle.WaitOne(400, $false)) { return $list }
                $tcp.EndConnect($ar)
            } catch { return $list }
            finally { $tcp.Close() }

            try {
                Import-Module RemoteDesktop -ErrorAction Stop
                $colls = @(Get-RDSessionCollection -ConnectionBroker $brokerHost -ErrorAction SilentlyContinue)
                if ($colls.Count -gt 0) {
                    foreach ($c in $colls) {
                        $hosts = @(Get-RDSessionHost -CollectionName $c.CollectionName -ConnectionBroker $brokerHost -ErrorAction SilentlyContinue)
                        foreach ($h in $hosts) {
                            $list += [PSCustomObject]@{
                                FarmShort  = $brokerHost.Split('.')[0]
                                BrokerFQDN = $brokerHost
                                Collection = [string]$c.CollectionName
                                HostShort  = [string]$h.SessionHost.Split('.')[0]
                                HostFQDN   = [string]$h.SessionHost
                                RawMode    = [string]$h.NewConnectionAllowed
                            }
                        }
                    }
                } else {
                    $hosts = @(Get-RDSessionHost -ConnectionBroker $brokerHost -ErrorAction SilentlyContinue)
                    foreach ($h in $hosts) {
                        $list += [PSCustomObject]@{
                            FarmShort  = $brokerHost.Split('.')[0]
                            BrokerFQDN = $brokerHost
                            Collection = [string]$h.CollectionName
                            HostShort  = [string]$h.SessionHost.Split('.')[0]
                            HostFQDN   = [string]$h.SessionHost
                            RawMode    = [string]$h.NewConnectionAllowed
                        }
                    }
                }
            } catch {}
            return $list
        }

        $pool = [runspacefactory]::CreateRunspacePool(1, [Math]::Max(1, $script:candidateBrokers.Count))
        $pool.Open()
        $nJobs = @()
        foreach ($b in $script:candidateBrokers) {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool
            [void]$ps.AddScript($nodeWorker).AddArgument($b)
            $nJobs += [PSCustomObject]@{ PS = $ps; Handle = $ps.BeginInvoke() }
        }

        $dt = New-Object System.Data.DataTable
        [void]$dt.Columns.Add("Ферма", [string])
        [void]$dt.Columns.Add("Коллекция", [string])
        [void]$dt.Columns.Add("Сервер RDSH", [string])
        [void]$dt.Columns.Add("FQDN узла", [string])
        [void]$dt.Columns.Add("Новые подключения", [string])
        [void]$dt.Columns.Add("Всего сессий", [int])
        [void]$dt.Columns.Add("Активных", [int])
        [void]$dt.Columns.Add("Отключенных", [int])
        [void]$dt.Columns.Add("BrokerHost", [string])

        foreach ($j in $nJobs) {
            try {
                $items = $j.PS.EndInvoke($j.Handle)
                foreach ($it in $items) {
                    if (-not $it) { continue }
                    $dispMode = switch ($it.RawMode) {
                        "Yes"            { "● Разрешены (Yes)" }
                        "NotUntilReboot" { "⏸ До перезагрузки (Drain)" }
                        "No"             { "✖ Запрещены (No)" }
                        default          { $it.RawMode }
                    }

                    $totS = 0; $actS = 0; $dscS = 0
                    if ($script:table) {
                        $matched = @($script:table.Select("HostServerFQDN = '$($it.HostFQDN)'"))
                        $totS = $matched.Count
                        foreach ($m in $matched) {
                            if ($m["Статус"] -eq "Активен") { $actS++ } else { $dscS++ }
                        }
                    }

                    $r = $dt.NewRow()
                    $r["Ферма"]             = $it.FarmShort
                    $r["Коллекция"]         = if ($it.Collection) { $it.Collection } else { "—" }
                    $r["Сервер RDSH"]       = $it.HostShort
                    $r["FQDN узла"]         = $it.HostFQDN
                    $r["Новые подключения"] = $dispMode
                    $r["Всего сессий"]      = $totS
                    $r["Активных"]          = $actS
                    $r["Отключенных"]       = $dscS
                    $r["BrokerHost"]        = $it.BrokerFQDN
                    $dt.Rows.Add($r)
                }
            } catch {}
            finally { $j.PS.Dispose() }
        }
        $pool.Close(); $pool.Dispose()

        if ($dt.Rows.Count -eq 0 -and $script:table -and $script:table.Rows.Count -gt 0) {
            $seenHosts = @{}
            foreach ($sr in $script:table.Rows) {
                $hFqdn = [string]$sr["HostServerFQDN"]
                if (-not $seenHosts.ContainsKey($hFqdn)) {
                    $seenHosts[$hFqdn] = $true
                    $drainStatus = "● Разрешены (Yes)"
                    try {
                        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $hFqdn)
                        $key = $reg.OpenSubKey("SYSTEM\CurrentControlSet\Control\Terminal Server")
                        if ($key) {
                            $dv = $key.GetValue("TSServerDrainMode")
                            if ($dv -eq 1) { $drainStatus = "⏸ До перезагрузки (Drain)" }
                            elseif ($dv -eq 2) { $drainStatus = "✖ Запрещены (No)" }
                            $key.Close()
                        }
                        $reg.Close()
                    } catch {}

                    $matched = @($script:table.Select("HostServerFQDN = '$hFqdn'"))
                    $actS = @($matched | Where-Object { $_["Статус"] -eq "Активен" }).Count
                    $r = $dt.NewRow()
                    $r["Ферма"]             = [string]$sr["Ферма"]
                    $r["Коллекция"]         = "RDS Farm"
                    $r["Сервер RDSH"]       = [string]$sr["Сервер RDSH"]
                    $r["FQDN узла"]         = $hFqdn
                    $r["Новые подключения"] = $drainStatus
                    $r["Всего сессий"]      = $matched.Count
                    $r["Активных"]          = $actS
                    $r["Отключенных"]       = ($matched.Count - $actS)
                    $r["BrokerHost"]        = [string]$sr["BrokerHost"]
                    $dt.Rows.Add($r)
                }
            }
        }

        $dt.DefaultView.Sort = "Ферма ASC, [Сервер RDSH] ASC"
        $script:nodesTable = $dt
        $nGrid.DataSource = $script:nodesTable.DefaultView
        if ($nGrid.Columns.Contains("BrokerHost")) { $nGrid.Columns["BrokerHost"].Visible = $false }
        if ($nGrid.Columns.Contains("Новые подключения")) { $nGrid.Columns["Новые подключения"].FillWeight = 135 }

        $btnNRefresh.Enabled = $true
        & $FilterNodes
    }

    $ApplyNodeStateChange = {
        param([string]$targetMode, [string]$modeTitle)
        if ($nGrid.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Выберите один или несколько серверов RDSH в таблице.", "Управление узлами", "OK", "Information")
            return
        }

        $hostsList = @()
        foreach ($sr in $nGrid.SelectedRows) { $hostsList += [string]$sr.Cells["Сервер RDSH"].Value }

        $confirmMsg = "Установить режим '$modeTitle' для выбранных серверов RDSH ($($hostsList -join ', '))?"
        if ([System.Windows.Forms.MessageBox]::Show($confirmMsg, "Изменение режима подключений RDSH", "YesNo", "Question") -eq "Yes") {
            $lblNStatus.Text = "Применение режима '$modeTitle'..."
            $nForm.Refresh()
            $okCount = 0
            foreach ($sr in $nGrid.SelectedRows) {
                $bHost = [string]$sr.Cells["BrokerHost"].Value
                $hFqdn = [string]$sr.Cells["FQDN узла"].Value
                if (Set-RdsNodeDrainState $bHost $hFqdn $targetMode) { $okCount++ }
            }
            & $LoadNodes
            $lblNStatus.Text = "Режим успешно изменен для $okCount из $($hostsList.Count) узлов."
        }
    }

    $cbNFarm.Add_SelectedIndexChanged($FilterNodes)
    $btnNRefresh.Add_Click($LoadNodes)
    $btnNAllow.Add_Click({ & $ApplyNodeStateChange "Yes" "Разрешены (Yes)" })
    $btnNReboot.Add_Click({ & $ApplyNodeStateChange "NotUntilReboot" "Запретить до перезагрузки (NotUntilReboot)" })
    $btnNDeny.Add_Click({ & $ApplyNodeStateChange "No" "Полный запрет (No)" })

    $nForm.Add_Shown($LoadNodes)
    [void]$nForm.ShowDialog($form)
}

# --- КАСТОМНАЯ ОТРИСОВКА ПИЛЮЛЬ СТАТУСА И ПРОСТОЯ ---
$grid.Add_CellPainting({
    param($sender, $e)
    if ($e.RowIndex -lt 0 -or $e.ColumnIndex -lt 0) { return }
    $colName = $grid.Columns[$e.ColumnIndex].Name

    if ($colName -eq "Статус") {
        $e.PaintBackground($e.ClipBounds, $true)
        $val = [string]$e.Value
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $pillW = [Math]::Min(108, $e.CellBounds.Width - 12)
        $pillH = 22
        $pillX = $e.CellBounds.X + 6
        $pillY = $e.CellBounds.Y + [int](($e.CellBounds.Height - $pillH) / 2)
        $rect  = New-Object System.Drawing.Rectangle($pillX, $pillY, $pillW, $pillH)

        if ($val -eq "Активен") {
            $bgB  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(20, 83, 45))
            $penB = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(34, 197, 94), 1)
            $txtC = [System.Drawing.Color]::FromArgb(134, 239, 172)
            $disp = "● Активен"
        } else {
            $bgB  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30, 41, 59))
            $penB = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(71, 85, 105), 1)
            $txtC = [System.Drawing.Color]::FromArgb(148, 163, 184)
            $disp = "○ Отключен"
        }

        $path = [DarkUI]::GetRoundedRect($rect, 10)
        $g.FillPath($bgB, $path)
        $g.DrawPath($penB, $path)
        [System.Windows.Forms.TextRenderer]::DrawText(
            $g, $disp,
            (New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)),
            $rect, $txtC,
            [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter
        )
        $path.Dispose(); $bgB.Dispose(); $penB.Dispose()
        $e.Handled = $true
    }
    elseif ($colName -eq "Простой (мин)") {
        $idleVal = 0
        if ([int]::TryParse([string]$e.Value, [ref]$idleVal) -and $idleVal -ge 60) {
            $e.PaintBackground($e.ClipBounds, $true)
            $g = $e.Graphics
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

            $pillW = [Math]::Min(86, $e.CellBounds.Width - 12)
            $pillH = 20
            $pillX = $e.CellBounds.X + 6
            $pillY = $e.CellBounds.Y + [int](($e.CellBounds.Height - $pillH) / 2)
            $rect  = New-Object System.Drawing.Rectangle($pillX, $pillY, $pillW, $pillH)

            $bgB  = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(120, 53, 15))
            $penB = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(245, 158, 11), 1)
            $path = [DarkUI]::GetRoundedRect($rect, 8)
            $g.FillPath($bgB, $path)
            $g.DrawPath($penB, $path)
            [System.Windows.Forms.TextRenderer]::DrawText(
                $g, "$idleVal мин",
                (New-Object System.Drawing.Font("Segoe UI Semibold", 8.5, [System.Drawing.FontStyle]::Bold)),
                $rect, [System.Drawing.Color]::FromArgb(253, 230, 138),
                [System.Windows.Forms.TextFormatFlags]::HorizontalCenter -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter
            )
            $path.Dispose(); $bgB.Dispose(); $penB.Dispose()
            $e.Handled = $true
        }
    }
})

# --- ОКНО ВВОДА И СОХРАНЕНИЯ УЧЕТНЫХ ДАННЫХ SSH ---
function Request-FSLogixCredentials {
    $cForm = New-Object System.Windows.Forms.Form
    $cForm.Text = "SSH Авторизация — Сервер профилей FSLogix"
    $cForm.Size = New-Object System.Drawing.Size(430, 270)
    $cForm.StartPosition = "CenterParent"
    $cForm.FormBorderStyle = "FixedDialog"
    $cForm.MaximizeBox = $false; $cForm.MinimizeBox = $false
    $cForm.BackColor = $clrBgMain
    $cForm.ForeColor = $clrTextPrimary
    $cForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $cForm.Add_HandleCreated({ [DarkUI]::UseImmersiveDarkMode($cForm.Handle) })

    $l1 = New-Object System.Windows.Forms.Label
    $l1.Text = "Логин SSH (root или пользователь с sudo):"
    $l1.ForeColor = $clrTextMuted
    $l1.Location = New-Object System.Drawing.Point(20, 20); $l1.AutoSize = $true

    $tUser = New-Object System.Windows.Forms.TextBox
    $tUser.BackColor = $clrBgCard; $tUser.ForeColor = $clrTextPrimary; $tUser.BorderStyle = "FixedSingle"
    $tUser.Location = New-Object System.Drawing.Point(20, 42); $tUser.Size = New-Object System.Drawing.Size(370, 25)
    $tUser.Text = "root"

    $l2 = New-Object System.Windows.Forms.Label
    $l2.Text = "Пароль SSH / sudo (шифруется Windows DPAPI):"
    $l2.ForeColor = $clrTextMuted
    $l2.Location = New-Object System.Drawing.Point(20, 80); $l2.AutoSize = $true

    $tPass = New-Object System.Windows.Forms.TextBox
    $tPass.BackColor = $clrBgCard; $tPass.ForeColor = $clrTextPrimary; $tPass.BorderStyle = "FixedSingle"
    $tPass.Location = New-Object System.Drawing.Point(20, 102); $tPass.Size = New-Object System.Drawing.Size(370, 25)
    $tPass.PasswordChar = '*'

    $chkSave = New-Object System.Windows.Forms.CheckBox
    $chkSave.Text = "Сохранить зашифрованным в профиле Windows"
    $chkSave.ForeColor = $clrTextPrimary
    $chkSave.Location = New-Object System.Drawing.Point(20, 140); $chkSave.AutoSize = $true
    $chkSave.Checked = $true

    $bOk     = New-ModernButton "Сохранить и подключиться" 20  178 230 34 ([System.Drawing.Color]::FromArgb(5, 150, 105)) ([System.Drawing.Color]::FromArgb(16, 185, 129))
    $bCancel = New-ModernButton "Отмена"                   260 178 130 34 ([System.Drawing.Color]::FromArgb(51, 65, 85))  ([System.Drawing.Color]::FromArgb(71, 85, 105))

    $script:credResult = $null
    $bOk.Add_Click({
        if ([string]::IsNullOrWhiteSpace($tUser.Text) -or [string]::IsNullOrWhiteSpace($tPass.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Введите логин и пароль SSH.", "Внимание", "OK", "Warning")
            return
        }
        $secPass = ConvertTo-SecureString $tPass.Text -AsPlainText -Force
        $credObj = New-Object System.Management.Automation.PSCredential($tUser.Text.Trim(), $secPass)
        if ($chkSave.Checked) {
            try { $credObj | Export-Clixml -Path $script:credFile -Force } catch {}
        }
        $script:credResult = $credObj
        $cForm.DialogResult = "OK"
        $cForm.Close()
    })
    $bCancel.Add_Click({ $cForm.Close() })

    $cForm.Controls.AddRange(@($l1, $tUser, $l2, $tPass, $chkSave, $bOk, $bCancel))
    [void]$cForm.ShowDialog($form)
    return $script:credResult
}

function Get-FSLogixCredential([bool]$forcePrompt = $false) {
    if (-not $forcePrompt -and (Test-Path $script:credFile)) {
        try { return (Import-Clixml -Path $script:credFile) } catch {}
    }
    return (Request-FSLogixCredentials)
}

function Invoke-UbuntuSsh([string]$targetHost, [string]$remoteBashCmd, [System.Management.Automation.PSCredential]$cred) {
    Import-Module Posh-SSH -ErrorAction Stop
    $sess = New-SSHSession -ComputerName $targetHost -Credential $cred -AcceptKey -ConnectionTimeout 10 -ErrorAction Stop
    try {
        $plainPass   = $cred.GetNetworkCredential().Password
        $b64Cmd      = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($remoteBashCmd))
        $escapedPass = $plainPass.Replace("'", "'\\''")
        $fullCmd = if ($cred.UserName -eq "root") {
            "echo $b64Cmd | base64 -d | bash"
        } else {
            "echo '$escapedPass' | sudo -S -p '' bash -c 'echo $b64Cmd | base64 -d | bash'"
        }
        $res = Invoke-SSHCommand -SSHSession $sess -Command $fullCmd -TimeOut 20 -ErrorAction Stop
        return ($res.Output -join "`n")
    } finally {
        Remove-SSHSession -SSHSession $sess | Out-Null
    }
}

# --- ОКНО УПРАВЛЕНИЯ FSLOGIX (С ВЫБОРОМ СЕРВЕРА) ---
$ShowFSLogixManager = {
    $initialUser = ""
    if ($grid.SelectedRows.Count -gt 0) {
        $initialUser = [string]$grid.SelectedRows[0].Cells["Логин"].Value
        $initialUser = $initialUser.Split('\')[-1]
    }

    if ([string]::IsNullOrWhiteSpace($script:fslogixHost)) {
        $inputHost = [Microsoft.VisualBasic.Interaction]::InputBox("Введите IP-адрес или FQDN сервера хранения профилей FSLogix (Linux / Samba SSH):", "Настройка сервера FSLogix", "")
        if ([string]::IsNullOrWhiteSpace($inputHost)) { return }
        Save-AppSettings $script:candidateBrokers $inputHost
        $cardFslogix.ValueText = $script:fslogixHost
        $cardFslogix.Invalidate()
    }

    $cred = Get-FSLogixCredential $false
    if (-not $cred) { return }

    $fForm = New-Object System.Windows.Forms.Form
    $fForm.Text = "FSLogix VHDX Lock Manager — ($script:fslogixHost)"
    $fForm.Size = New-Object System.Drawing.Size(1160, 580)
    $fForm.StartPosition = "CenterParent"
    $fForm.BackColor = $clrBgMain
    $fForm.ForeColor = $clrTextPrimary
    $fForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $fForm.Add_HandleCreated({ [DarkUI]::UseImmersiveDarkMode($fForm.Handle) })

    $fTop = New-Object System.Windows.Forms.Panel
    $fTop.Dock = "Top"; $fTop.Height = 58
    $fTop.BackColor = $clrBgSurface

    $lblSrv = New-Object System.Windows.Forms.Label
    $lblSrv.Text = "Сервер FSLogix:"
    $lblSrv.ForeColor = $clrTextMuted
    $lblSrv.Location = New-Object System.Drawing.Point(14, 19); $lblSrv.AutoSize = $true

    $txtSrv = New-Object System.Windows.Forms.TextBox
    $txtSrv.BackColor = $clrBgCard; $txtSrv.ForeColor = $clrTextPrimary; $txtSrv.BorderStyle = "FixedSingle"
    $txtSrv.Location = New-Object System.Drawing.Point(115, 16); $txtSrv.Size = New-Object System.Drawing.Size(145, 25)
    $txtSrv.Text = $script:fslogixHost

    $lblU = New-Object System.Windows.Forms.Label
    $lblU.Text = "Фильтр по логину:"
    $lblU.ForeColor = $clrTextMuted
    $lblU.Location = New-Object System.Drawing.Point(275, 19); $lblU.AutoSize = $true

    $txtU = New-Object System.Windows.Forms.TextBox
    $txtU.BackColor = $clrBgCard; $txtU.ForeColor = $clrTextPrimary; $txtU.BorderStyle = "FixedSingle"
    $txtU.Location = New-Object System.Drawing.Point(392, 16); $txtU.Size = New-Object System.Drawing.Size(150, 25)
    $txtU.Text = $initialUser

    $btnScan   = New-ModernButton "⟳ Опросить сервер"                555 12 155 34 ([System.Drawing.Color]::FromArgb(37, 99, 235))  ([System.Drawing.Color]::FromArgb(59, 130, 246))
    $btnUnlock = New-ModernButton "⚡ Разблокировать выбранный VHDX" 718 12 245 34 ([System.Drawing.Color]::FromArgb(185, 28, 28))  ([System.Drawing.Color]::FromArgb(239, 68, 68))
    $btnCreds  = New-ModernButton "⚙ Пароль SSH"                     971 12 150 34 ([System.Drawing.Color]::FromArgb(51, 65, 85))   ([System.Drawing.Color]::FromArgb(71, 85, 105))

    $fTop.Controls.AddRange(@($lblSrv, $txtSrv, $lblU, $txtU, $btnScan, $btnUnlock, $btnCreds))

    $fStatusPanel = New-Object System.Windows.Forms.Panel
    $fStatusPanel.Dock = "Bottom"; $fStatusPanel.Height = 32
    $fStatusPanel.BackColor = $clrBgSurface

    $lblFStatus = New-Object System.Windows.Forms.Label
    $lblFStatus.Text = "Подключение к $script:fslogixHost..."
    $lblFStatus.ForeColor = $clrAccentBlue
    $lblFStatus.Location = New-Object System.Drawing.Point(16, 7); $lblFStatus.AutoSize = $true
    $fStatusPanel.Controls.Add($lblFStatus)

    $fGrid = New-Object System.Windows.Forms.DataGridView
    $fGrid.Dock = "Fill"; $fGrid.AutoSizeColumnsMode = "Fill"
    $fGrid.SelectionMode = "FullRowSelect"; $fGrid.MultiSelect = $true
    $fGrid.ReadOnly = $true; $fGrid.AllowUserToAddRows = $false
    $fGrid.RowHeadersVisible = $false
    $fGrid.BackgroundColor = $clrBgMain
    $fGrid.BorderStyle = "None"
    $fGrid.CellBorderStyle = "SingleHorizontal"
    $fGrid.GridColor = $clrBgCard
    $fGrid.EnableHeadersVisualStyles = $false
    $fGrid.ColumnHeadersBorderStyle = "None"
    $fGrid.ColumnHeadersHeight = 36
    $fGrid.ColumnHeadersDefaultCellStyle.BackColor = $clrBgCard
    $fGrid.ColumnHeadersDefaultCellStyle.ForeColor = $clrAccentBlue
    $fGrid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9, [System.Drawing.FontStyle]::Bold)
    $fGrid.DefaultCellStyle.BackColor = $clrBgSurface
    $fGrid.DefaultCellStyle.ForeColor = $clrTextPrimary
    $fGrid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(88, 28, 135)
    $fGrid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $fGrid.RowTemplate.Height = 30

    $fForm.Controls.AddRange(@($fGrid, $fTop, $fStatusPanel))

    $script:locksTable = $null

    $LoadLocks = {
        $curSrv = $txtSrv.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($curSrv)) { return }
        if ($curSrv -ne $script:fslogixHost) {
            Save-AppSettings $script:candidateBrokers $curSrv
            $cardFslogix.ValueText = $script:fslogixHost
            $cardFslogix.Invalidate()
            $fForm.Text = "FSLogix VHDX Lock Manager — ($script:fslogixHost)"
        }

        $lblFStatus.Text = "Запрос блокировок Samba (smbstatus -L) на $curSrv..."
        $fForm.Refresh()

        $bashLines = @(
            'smbstatus -L -n 2>/dev/null | awk ''NR>3 && NF>=6 && ($0 ~ /\.vhdx|\.VHDX|\.vhd|\.lock|\.meta/) {'
            '    pid=$1; rw=$4;'
            '    match($0, /[A-Z][a-z]{2}[ ]+[A-Z][a-z]{2}[ ]+[0-9]+[ ]+[0-9:]+[ ]+[0-9]{4}/);'
            '    if (RSTART > 0) {'
            '        fpath = substr($0, 1, RSTART-1);'
            '        sub(/^[0-9]+[ ]+[0-9]+[ ]+[A-Z0-9_]+[ ]+[A-Z0-9_]+[ ]+[A-Z0-9_]+[ ]+/, "", fpath);'
            '        gsub(/[ ]+$/, "", fpath);'
            '        ltime = substr($0, RSTART, RLENGTH);'
            '        print pid "|" rw "|" fpath "|" ltime'
            '    }'
            '}'''
        )
        $bashScript = $bashLines -join "`n"

        try {
            $rawOut = Invoke-UbuntuSsh $curSrv $bashScript $cred
            $dt = New-Object System.Data.DataTable
            [void]$dt.Columns.Add("PID (smbd)", [string])
            [void]$dt.Columns.Add("Пользователь (по пути)", [string])
            [void]$dt.Columns.Add("Режим", [string])
            [void]$dt.Columns.Add("Файл контейнера (VHDX)", [string])
            [void]$dt.Columns.Add("Время блокировки", [string])

            if (-not [string]::IsNullOrWhiteSpace($rawOut)) {
                foreach ($line in ($rawOut -split "`r?`n")) {
                    if ([string]::IsNullOrWhiteSpace($line) -or ($line -notmatch '\|')) { continue }
                    $parts = $line.Split('|')
                    if ($parts.Count -ge 3) {
                        $pidVal  = $parts[0].Trim()
                        $rwVal   = $parts[1].Trim()
                        $fileVal = $parts[2].Trim()
                        $timeVal = if ($parts.Count -ge 4) { $parts[3].Trim() } else { "" }

                        $guessedUser = ""
                        if ($fileVal -match 'Profile_([^\\/\.]+)') { $guessedUser = $Matches[1] }
                        elseif ($fileVal -match '([^\\/]+)\.vhdx') { $guessedUser = $Matches[1] }

                        $r = $dt.NewRow()
                        $r["PID (smbd)"]             = $pidVal
                        $r["Пользователь (по пути)"] = $guessedUser
                        $r["Режим"]                  = $rwVal
                        $r["Файл контейнера (VHDX)"] = $fileVal
                        $r["Время блокировки"]       = $timeVal
                        $dt.Rows.Add($r)
                    }
                }
            }

            $script:locksTable = $dt
            $fGrid.DataSource = $script:locksTable.DefaultView
            if ($fGrid.Columns.Contains("PID (smbd)")) { $fGrid.Columns["PID (smbd)"].FillWeight = 45 }
            if ($fGrid.Columns.Contains("Режим")) { $fGrid.Columns["Режим"].FillWeight = 45 }
            if ($fGrid.Columns.Contains("Пользователь (по пути)")) { $fGrid.Columns["Пользователь (по пути)"].FillWeight = 75 }

            & $FilterLocks
        } catch {
            $lblFStatus.Text = "Ошибка SSH: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Не удалось выполнить команду на $curSrv :`n$($_.Exception.Message)", "Ошибка подключения SSH", "OK", "Error")
        }
    }

    $FilterLocks = {
        if (-not $script:locksTable) { return }
        $uFilter = $txtU.Text.Trim().Replace("'", "''")
        if (-not [string]::IsNullOrWhiteSpace($uFilter)) {
            $script:locksTable.DefaultView.RowFilter = "[Файл контейнера (VHDX)] LIKE '%$uFilter%' OR [Пользователь (по пути)] LIKE '%$uFilter%'"
        } else {
            $script:locksTable.DefaultView.RowFilter = ""
        }
        $lblFStatus.Text = "Найдено блокировок VHDX: $($script:locksTable.DefaultView.Count) (всего открыто на сервере: $($script:locksTable.Rows.Count))"
    }

    $txtU.Add_TextChanged($FilterLocks)
    $btnScan.Add_Click($LoadLocks)

    $btnCreds.Add_Click({
        $newCred = Request-FSLogixCredentials
        if ($newCred) {
            $cred = $newCred
            & $LoadLocks
        }
    })

    $btnUnlock.Add_Click({
        if ($fGrid.SelectedRows.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Выберите одну или несколько строк с заблокированным VHDX.", "Разблокировка", "OK", "Information")
            return
        }

        $pidsToKill = @()
        $filesList  = @()
        foreach ($selRow in $fGrid.SelectedRows) {
            $p = [string]$selRow.Cells["PID (smbd)"].Value
            $f = [string]$selRow.Cells["Файл контейнера (VHDX)"].Value
            if ($p -match '^\d+$' -and ($pidsToKill -notcontains $p)) { $pidsToKill += $p }
            $filesList += $f
        }

        if ($pidsToKill.Count -eq 0) { return }

        $curSrv = $txtSrv.Text.Trim()
        $msg = "Снять блокировку контейнера FSLogix на сервере $curSrv?`n`nБудут принудительно закрыты процессы smbd (PID: $($pidsToKill -join ', ')) для файлов:`n" + ($filesList -join "`n")
        if ([System.Windows.Forms.MessageBox]::Show($msg, "Подтверждение разблокировки FSLogix", "YesNo", "Warning") -eq "Yes") {
            try {
                $killCmd = "kill -9 " + ($pidsToKill -join " ") + " 2>/dev/null; echo OK"
                [void](Invoke-UbuntuSsh $curSrv $killCmd $cred)
                [System.Windows.Forms.MessageBox]::Show("Блокировка успешно снята (PID: $($pidsToKill -join ', ')).`nПользователь может подключаться к RDS.", "Успешно", "OK", "Information")
                & $LoadLocks
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Ошибка при снятии блокировки:`n$($_.Exception.Message)", "Ошибка", "OK", "Error")
            }
        }
    })

    $fForm.Add_Shown($LoadLocks)
    [void]$fForm.ShowDialog($form)
}

# --- ФУНКЦИЯ ТЕНЕВОГО ПОДКЛЮЧЕНИЯ БЕЗ ЗАПРОСА ---
function Start-SilentShadow([bool]$withControl) {
    if ($grid.SelectedRows.Count -eq 0) { return }
    $row        = $grid.SelectedRows[0]
    $sessId     = $row.Cells["ID"].Value
    $hostServer = $row.Cells["HostServerFQDN"].Value

    try {
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine, $hostServer)
        $key = $reg.CreateSubKey("SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services")
        if ($key.GetValue("Shadow") -ne 2) {
            $key.SetValue("Shadow", 2, [Microsoft.Win32.RegistryValueKind]::DWord)
        }
        $key.Close(); $reg.Close()
    } catch {}

    $args = if ($withControl) {
        "/shadow:$sessId /v:$hostServer /control /noConsentPrompt"
    } else {
        "/shadow:$sessId /v:$hostServer /noConsentPrompt"
    }
    Start-Process "mstsc.exe" -ArgumentList $args
}

# --- ОКНО ДИСПЕТЧЕРА ПРОЦЕССОВ СЕССИИ ---
$ShowUserProcesses = {
    if ($grid.SelectedRows.Count -eq 0) { return }
    $row        = $grid.SelectedRows[0]
    $user       = $row.Cells["Логин"].Value
    $fio        = $row.Cells["ФИО (AD)"].Value
    $sessId     = [int]$row.Cells["ID"].Value
    $hostServer = $row.Cells["HostServerFQDN"].Value

    $pForm = New-Object System.Windows.Forms.Form
    $pForm.Text = "Процессы сессии: $fio ($user) — ID: $sessId на $hostServer"
    $pForm.Size = New-Object System.Drawing.Size(820, 520)
    $pForm.StartPosition = "CenterParent"
    $pForm.BackColor = $clrBgMain
    $pForm.ForeColor = $clrTextPrimary
    $pForm.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $pForm.Add_HandleCreated({ [DarkUI]::UseImmersiveDarkMode($pForm.Handle) })

    $pTop = New-Object System.Windows.Forms.Panel
    $pTop.Dock = "Top"; $pTop.Height = 50
    $pTop.BackColor = $clrBgSurface

    $btnPUpdate = New-ModernButton "⟳ Обновить"               12  8 120 34 ([System.Drawing.Color]::FromArgb(37, 99, 235)) ([System.Drawing.Color]::FromArgb(59, 130, 246))
    $btnPKill   = New-ModernButton "✖ Завершить процесс (Kill)" 140 8 210 34 ([System.Drawing.Color]::FromArgb(185, 28, 28)) ([System.Drawing.Color]::FromArgb(239, 68, 68))
    $lblPInfo   = New-Object System.Windows.Forms.Label
    $lblPInfo.ForeColor = $clrAccentBlue
    $lblPInfo.Location = New-Object System.Drawing.Point(365, 16); $lblPInfo.AutoSize = $true
    $pTop.Controls.AddRange(@($btnPUpdate, $btnPKill, $lblPInfo))

    $pGrid = New-Object System.Windows.Forms.DataGridView
    $pGrid.Dock = "Fill"; $pGrid.AutoSizeColumnsMode = "Fill"
    $pGrid.SelectionMode = "FullRowSelect"; $pGrid.ReadOnly = $true
    $pGrid.AllowUserToAddRows = $false; $pGrid.RowHeadersVisible = $false
    $pGrid.BackgroundColor = $clrBgMain
    $pGrid.BorderStyle = "None"
    $pGrid.CellBorderStyle = "SingleHorizontal"
    $pGrid.GridColor = $clrBgCard
    $pGrid.EnableHeadersVisualStyles = $false
    $pGrid.ColumnHeadersBorderStyle = "None"
    $pGrid.ColumnHeadersHeight = 36
    $pGrid.ColumnHeadersDefaultCellStyle.BackColor = $clrBgCard
    $pGrid.ColumnHeadersDefaultCellStyle.ForeColor = $clrAccentBlue
    $pGrid.ColumnHeadersDefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9, [System.Drawing.FontStyle]::Bold)
    $pGrid.DefaultCellStyle.BackColor = $clrBgSurface
    $pGrid.DefaultCellStyle.ForeColor = $clrTextPrimary
    $pGrid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::FromArgb(30, 58, 138)
    $pGrid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::White
    $pGrid.RowTemplate.Height = 28

    $pForm.Controls.AddRange(@($pGrid, $pTop))

    $LoadProcs = {
        $lblPInfo.Text = "Запрос процессов с $hostServer..."
        $pForm.Refresh()
        $dt = New-Object System.Data.DataTable
        [void]$dt.Columns.Add("PID", [int])
        [void]$dt.Columns.Add("Имя процесса", [string])
        [void]$dt.Columns.Add("Память (МБ)", [double])
        [void]$dt.Columns.Add("Время запуска", [string])

        try {
            $procs = Get-WmiObject Win32_Process -ComputerName $hostServer -Filter "SessionId = $sessId" -ErrorAction Stop
            foreach ($p in $procs) {
                $r = $dt.NewRow()
                $r["PID"]          = [int]$p.ProcessId
                $r["Имя процесса"] = [string]$p.Name
                $r["Память (МБ)"]  = [math]::Round(($p.WorkingSetSize / 1MB), 1)
                $startStr = ""
                try { $startStr = $p.ConvertToDateTime($p.CreationDate).ToString("HH:mm:ss") } catch {}
                $r["Время запуска"] = $startStr
                $dt.Rows.Add($r)
            }
            $dt.DefaultView.Sort = "Память (МБ) DESC"
            $pGrid.DataSource = $dt.DefaultView
            $lblPInfo.Text = "Активных процессов в сессии: $($dt.Rows.Count)"
        } catch {
            $lblPInfo.Text = "Ошибка WMI: $($_.Exception.Message)"
        }
    }

    $btnPUpdate.Add_Click($LoadProcs)
    $btnPKill.Add_Click({
        if ($pGrid.SelectedRows.Count -eq 0) { return }
        $pidVal = [int]$pGrid.SelectedRows[0].Cells["PID"].Value
        $pName  = $pGrid.SelectedRows[0].Cells["Имя процесса"].Value
        if ([System.Windows.Forms.MessageBox]::Show("Принудительно завершить процесс '$pName' (PID: $pidVal)?", "Завершение процесса", "YesNo", "Warning") -eq "Yes") {
            try {
                $procObj = Get-WmiObject Win32_Process -ComputerName $hostServer -Filter "ProcessId = $pidVal" -ErrorAction Stop
                if ($procObj) { [void]$procObj.Terminate() }
            } catch {
                taskkill /S $hostServer /PID $pidVal /F | Out-Null
            }
            & $LoadProcs
        }
    })

    $pForm.Add_Shown($LoadProcs)
    [void]$pForm.ShowDialog($form)
}

# --- ФИЛЬТРАЦИЯ ---
$ApplyFilters = {
    if (-not $script:table) { return }
    $filters = @()

    if ($cbBrokers.SelectedIndex -gt 0) {
        $selectedBroker = $cbBrokers.SelectedItem.ToString().Split(' ')[0]
        $filters += "Ферма = '$selectedBroker'"
    }

    if ($cbState.SelectedIndex -eq 1) {
        $filters += "Статус = 'Активен'"
    } elseif ($cbState.SelectedIndex -eq 2) {
        $filters += "Статус = 'Отключен'"
    }

    $search = $txtSearch.Text.Trim().Replace("'", "''")
    if (-not [string]::IsNullOrWhiteSpace($search)) {
        $filters += "(Логин LIKE '%$search%' OR [ФИО (AD)] LIKE '%$search%' OR [Отдел / Должность] LIKE '%$search%' OR [Сервер RDSH] LIKE '%$search%' OR [IP брокера] LIKE '%$search%' OR Статус LIKE '%$search%')"
    }

    if ($filters.Count -gt 0) {
        $script:table.DefaultView.RowFilter = $filters -join " AND "
    } else {
        $script:table.DefaultView.RowFilter = ""
    }
    $lblStatus.Text = "Отображено сессий: $($script:table.DefaultView.Count) из $($script:table.Rows.Count)   |   Последнее обновление: $(Get-Date -Format 'HH:mm:ss')"
}

$cardTotal.Add_Click({ $cbState.SelectedIndex = 0 })
$cardActive.Add_Click({ $cbState.SelectedIndex = 1 })
$cardDisc.Add_Click({ $cbState.SelectedIndex = 2 })
$cardBrokers.Add_Click($ShowNodesManager)
$cardFslogix.Add_Click($ShowFSLogixManager)

# --- ПАРАЛЛЕЛЬНЫЙ ОПРОС БРОКЕРОВ ---
$brokerWorkerScript = {
    param([string]$brokerHost)

    $result = [PSCustomObject]@{
        Broker   = $brokerHost
        Short    = $brokerHost.Split('.')[0]
        IP       = ""
        Online   = $false
        Sessions = @()
    }

    try {
        $ips = [System.Net.Dns]::GetHostAddresses($brokerHost) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
        if ($ips) { $result.IP = $ips[0].IPAddressToString }
    } catch { return $result }

    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $tcp.BeginConnect($brokerHost, 135, $null, $null)
        $ok = $async.AsyncWaitHandle.WaitOne(400, $false)
        if (-not $ok) { return $result }
        $tcp.EndConnect($async)
    } catch { return $result }
    finally { $tcp.Close() }

    try {
        Import-Module RemoteDesktop -ErrorAction Stop
        $rawSessions = Get-RDUserSession -ConnectionBroker $brokerHost -ErrorAction Stop
        $result.Online = $true

        if ($rawSessions) {
            $parsedList = New-Object System.Collections.Generic.List[object]
            foreach ($s in $rawSessions) {
                $dt = [DBNull]::Value
                if ($s.CreateTime) {
                    if ($s.CreateTime -is [datetime]) { $dt = $s.CreateTime }
                    else {
                        $p = [datetime]::MinValue
                        if ([datetime]::TryParse([string]$s.CreateTime, [ref]$p)) { $dt = $p }
                    }
                }

                $idle = 0
                if ($null -ne $s.IdleTime -and $s.IdleTime -ne "") {
                    if ($s.IdleTime -is [System.TimeSpan]) { $idle = [int][Math]::Floor($s.IdleTime.TotalMinutes) }
                    elseif ($s.IdleTime -as [double] -ne $null) { $idle = [int][Math]::Floor(([double]$s.IdleTime) / 60000) }
                    else {
                        $ts = [TimeSpan]::Zero
                        if ([TimeSpan]::TryParse([string]$s.IdleTime, [ref]$ts)) { $idle = [int][Math]::Floor($ts.TotalMinutes) }
                    }
                }

                $rawState = [string]$s.SessionState
                $ruState = switch ($rawState) {
                    "STATE_ACTIVE"       { "Активен" }
                    "STATE_CONNECTED"    { "Подключен" }
                    "STATE_DISCONNECTED" { "Отключен" }
                    default              { $rawState }
                }

                $parsedList.Add([PSCustomObject]@{
                    UserName       = [string]$s.UserName
                    HostShort      = [string]$s.HostServer.Split('.')[0]
                    HostServerFQDN = [string]$s.HostServer
                    SessionState   = $ruState
                    SessionID      = [int]$s.UnifiedSessionId
                    CreateTime     = $dt
                    IdleMinutes    = $idle
                })
            }
            $result.Sessions = $parsedList
        }
    } catch {}

    return $result
}

$StartLoadSessions = {
    if ($script:isLoading) { return }

    if ($script:candidateBrokers.Count -eq 0) {
        $lblStatus.Text = "Не задан список брокеров RDS. Нажмите '⚙ Настройки', чтобы добавить фермы."
        $cardTotal.ValueText   = "0";     $cardTotal.Invalidate()
        $cardActive.ValueText  = "0";     $cardActive.Invalidate()
        $cardDisc.ValueText    = "0";     $cardDisc.Invalidate()
        $cardBrokers.ValueText = "0 / 0"; $cardBrokers.Invalidate()
        return
    }

    $script:isLoading = $true
    $btnRefresh.Enabled = $false
    $btnRefresh.Text = "⟳ Загрузка..."
    $progressBar.Width = [int]($form.Width * 0.15)
    $lblStatus.Text = "Параллельный опрос брокеров (0 из $($script:candidateBrokers.Count))..."

    if (-not [string]::IsNullOrWhiteSpace($script:fslogixHost)) {
        try {
            $tcpF = New-Object System.Net.Sockets.TcpClient
            $arF  = $tcpF.BeginConnect($script:fslogixHost, 22, $null, $null)
            if ($arF.AsyncWaitHandle.WaitOne(150, $false)) {
                $cardFslogix.SubText  = "● SSH/Samba ОНЛАЙН (Открыть VHDX)"
                $cardFslogix.SubColor = $clrAccentGreen
            } else {
                $cardFslogix.SubText  = "○ Нет ответа SSH (Нажмите для входа)"
                $cardFslogix.SubColor = $clrAccentAmber
            }
            $tcpF.Close()
            $cardFslogix.Invalidate()
        } catch {}
    } else {
        $cardFslogix.ValueText = "Не задан"
        $cardFslogix.SubText   = "⚙ Нажмите для указания сервера"
        $cardFslogix.SubColor  = $clrTextMuted
        $cardFslogix.Invalidate()
    }

    $script:runspacePool = [runspacefactory]::CreateRunspacePool(1, [Math]::Max(1, $script:candidateBrokers.Count))
    $script:runspacePool.Open()
    $script:jobs = @()

    foreach ($b in $script:candidateBrokers) {
        $ps = [powershell]::Create()
        $ps.RunspacePool = $script:runspacePool
        [void]$ps.AddScript($brokerWorkerScript).AddArgument($b)
        $script:jobs += [PSCustomObject]@{
            PS     = $ps
            Handle = $ps.BeginInvoke()
            Broker = $b
        }
    }
    $script:timer.Start()
}

$script:timer.Add_Tick({
    $doneCount = @($script:jobs | Where-Object { $_.Handle.IsCompleted }).Count
    $ratio = if ($script:jobs.Count -gt 0) { $doneCount / $script:jobs.Count } else { 1 }
    $progressBar.Width = [int]($form.Width * $ratio)
    $lblStatus.Text = "Параллельный опрос ферм ($doneCount из $($script:jobs.Count))..."

    if ($doneCount -lt $script:jobs.Count) { return }
    $script:timer.Stop()

    $newTable = New-Object System.Data.DataTable
    [void]$newTable.Columns.Add("Ферма", [string])
    [void]$newTable.Columns.Add("IP брокера", [string])
    [void]$newTable.Columns.Add("Логин", [string])
    [void]$newTable.Columns.Add("ФИО (AD)", [string])
    [void]$newTable.Columns.Add("Отдел / Должность", [string])
    [void]$newTable.Columns.Add("Сервер RDSH", [string])
    [void]$newTable.Columns.Add("Статус", [string])
    [void]$newTable.Columns.Add("ID", [int])
    [void]$newTable.Columns.Add("Время входа", [datetime])
    [void]$newTable.Columns.Add("Простой (мин)", [int])
    [void]$newTable.Columns.Add("BrokerHost", [string])
    [void]$newTable.Columns.Add("HostServerFQDN", [string])

    $onlineCount = 0
    $activeCount = 0
    $discCount   = 0

    $newTable.BeginLoadData()

    for ($i = 0; $i -lt $script:jobs.Count; $i++) {
        $job = $script:jobs[$i]
        try {
            $res = $job.PS.EndInvoke($job.Handle) | Select-Object -First 1
            if ($res) {
                if ($res.IP -and ($i + 1) -lt $cbBrokers.Items.Count) {
                    $cbBrokers.Items[$i + 1] = "$($res.Short) ($($res.IP))"
                }
                if ($res.Online) {
                    $onlineCount++
                    foreach ($s in $res.Sessions) {
                        $ad = Get-AdUserInfo $s.UserName
                        if ($s.SessionState -eq "Активен") { $activeCount++ } else { $discCount++ }

                        $row = $newTable.NewRow()
                        $row["Ферма"]             = $res.Short
                        $row["IP брокера"]        = $res.IP
                        $row["Логин"]             = $s.UserName
                        $row["ФИО (AD)"]          = $ad.FullName
                        $row["Отдел / Должность"] = $ad.Dept
                        $row["Сервер RDSH"]       = $s.HostShort
                        $row["Статус"]            = $s.SessionState
                        $row["ID"]                = $s.SessionID
                        $row["Время входа"]       = $s.CreateTime
                        $row["Простой (мин)"]     = $s.IdleMinutes
                        $row["BrokerHost"]        = $res.Broker
                        $row["HostServerFQDN"]    = $s.HostServerFQDN
                        $newTable.Rows.Add($row)
                    }
                }
            }
        } catch {} finally {
            $job.PS.Dispose()
        }
    }

    $newTable.EndLoadData()
    if ($script:runspacePool) {
        $script:runspacePool.Close()
        $script:runspacePool.Dispose()
        $script:runspacePool = $null
    }
    $script:jobs = @()

    $newTable.DefaultView.Sort = "Ферма ASC, [ФИО (AD)] ASC"
    $script:table = $newTable
    $grid.DataSource = $script:table.DefaultView

    foreach ($hiddenCol in @("BrokerHost", "HostServerFQDN")) {
        if ($grid.Columns.Contains($hiddenCol)) { $grid.Columns[$hiddenCol].Visible = $false }
    }
    if ($grid.Columns.Contains("Время входа")) {
        $grid.Columns["Время входа"].DefaultCellStyle.Format = "dd.MM.yyyy HH:mm:ss"
    }
    if ($grid.Columns.Contains("ID")) { $grid.Columns["ID"].FillWeight = 42 }
    if ($grid.Columns.Contains("Статус")) { $grid.Columns["Статус"].FillWeight = 72 }

    $cardTotal.ValueText   = [string]$newTable.Rows.Count; $cardTotal.Invalidate()
    $cardActive.ValueText  = [string]$activeCount;         $cardActive.Invalidate()
    $cardDisc.ValueText    = [string]$discCount;           $cardDisc.Invalidate()
    $cardBrokers.ValueText = "$onlineCount / $($script:candidateBrokers.Count)"; $cardBrokers.Invalidate()

    $progressBar.Width = 0
    $btnRefresh.Enabled = $true
    $btnRefresh.Text = "⟳ Обновить (F5)"
    $script:isLoading = $false

    & $ApplyFilters
})

# --- ОБРАБОТЧИКИ СОБЫТИЙ ---
$cbBrokers.Add_SelectedIndexChanged($ApplyFilters)
$cbState.Add_SelectedIndexChanged($ApplyFilters)
$txtSearch.Add_TextChanged($ApplyFilters)
$btnClearSearch.Add_Click({ $txtSearch.Text = "" })
$btnRefresh.Add_Click($StartLoadSessions)
$btnSettings.Add_Click($ShowSettingsDialog)

$chkAutoRefresh.Add_CheckedChanged({
    if ($chkAutoRefresh.Checked) { $script:autoTimer.Start() } else { $script:autoTimer.Stop() }
})
$script:autoTimer.Add_Tick({ & $StartLoadSessions })

$btnShadowControl.Add_Click({ Start-SilentShadow $true })
$btnShadowView.Add_Click({ Start-SilentShadow $false })
$miShadowCtrl.Add_Click({ Start-SilentShadow $true })
$miShadowView.Add_Click({ Start-SilentShadow $false })

$btnNodes.Add_Click($ShowNodesManager)
$miNodesMgr.Add_Click($ShowNodesManager)

$miNodeAllow.Add_Click({
    if ($grid.SelectedRows.Count -eq 0) { return }
    $r      = $grid.SelectedRows[0]
    $hShort = $r.Cells["Сервер RDSH"].Value
    $hFqdn  = $r.Cells["HostServerFQDN"].Value
    $bFqdn  = $r.Cells["BrokerHost"].Value
    if ([System.Windows.Forms.MessageBox]::Show("Разрешить новые подключения пользователей к серверу $hShort ($hFqdn)?", "Разрешение входа на RDSH", "YesNo", "Question") -eq "Yes") {
        if (Set-RdsNodeDrainState $bFqdn $hFqdn "Yes") {
            [System.Windows.Forms.MessageBox]::Show("Новые подключения к узлу $hShort РАЗРЕШЕНЫ (Yes).", "Узел RDSH", "OK", "Information")
        }
    }
})

$miNodeDrain.Add_Click({
    if ($grid.SelectedRows.Count -eq 0) { return }
    $r      = $grid.SelectedRows[0]
    $hShort = $r.Cells["Сервер RDSH"].Value
    $hFqdn  = $r.Cells["HostServerFQDN"].Value
    $bFqdn  = $r.Cells["BrokerHost"].Value
    if ([System.Windows.Forms.MessageBox]::Show("Запретить новые подключения к серверу $hShort ($hFqdn) (режим Drain)?`n`nТекущие пользователи продолжат работу, а новые будут направляться на другие узлы фермы.", "Перевод RDSH в Drain Mode", "YesNo", "Warning") -eq "Yes") {
        if (Set-RdsNodeDrainState $bFqdn $hFqdn "No") {
            [System.Windows.Forms.MessageBox]::Show("Новые подключения к узлу $hShort ЗАПРЕЩЕНЫ (Drain Mode).", "Узел RDSH", "OK", "Information")
        }
    }
})

$btnFSLogix.Add_Click($ShowFSLogixManager)
$miFSLogix.Add_Click($ShowFSLogixManager)

$btnProcesses.Add_Click($ShowUserProcesses)
$miProcesses.Add_Click($ShowUserProcesses)

$DoDisconnect = {
    if ($grid.SelectedRows.Count -eq 0) { return }
    $count = $grid.SelectedRows.Count
    if ([System.Windows.Forms.MessageBox]::Show("Отключить выбранные сессии ($count шт.)?`nПрограммы пользователей останутся запущенными.", "Отключение", "YesNo", "Question") -eq "Yes") {
        Ensure-RDModule
        foreach ($r in $grid.SelectedRows) {
            $sessId     = [int]$r.Cells["ID"].Value
            $hostServer = $r.Cells["HostServerFQDN"].Value
            try {
                Disconnect-RDUser -HostServer $hostServer -UnifiedSessionId $sessId -Force -ErrorAction Stop
            } catch {
                tsdiscon $sessId /server:$hostServer
            }
        }
        & $StartLoadSessions
    }
}
$btnDisconnect.Add_Click($DoDisconnect)
$miDisconnect.Add_Click($DoDisconnect)

$DoLogoff = {
    if ($grid.SelectedRows.Count -eq 0) { return }
    $count = $grid.SelectedRows.Count
    if ([System.Windows.Forms.MessageBox]::Show("Принудительно сбросить выбранные сессии ($count шт.)?`nНесохраненные данные будут потеряны!", "Сброс сессий", "YesNo", "Warning") -eq "Yes") {
        Ensure-RDModule
        foreach ($r in $grid.SelectedRows) {
            $sessId     = [int]$r.Cells["ID"].Value
            $hostServer = $r.Cells["HostServerFQDN"].Value
            $broker     = $r.Cells["BrokerHost"].Value
            try {
                Invoke-RDUserLogoff -HostServer $hostServer -UnifiedSessionId $sessId -Force -ErrorAction Stop
            } catch {
                try {
                    Invoke-RDUserLogoff -ConnectionBroker $broker -UnifiedSessionId $sessId -Force -ErrorAction Stop
                } catch {
                    logoff $sessId /server:$hostServer
                }
            }
        }
        & $StartLoadSessions
    }
}
$btnLogoff.Add_Click($DoLogoff)
$miLogoff.Add_Click($DoLogoff)

$DoSendMessage = {
    if ($grid.SelectedRows.Count -eq 0) { return }
    $count = $grid.SelectedRows.Count
    $msg = [Microsoft.VisualBasic.Interaction]::InputBox("Введите текст сообщения для выбранных пользователей ($count шт.):", "Отправка сообщения", "Уважаемые коллеги, пожалуйста, сохраните работу.")
    if ($msg) {
        Ensure-RDModule
        foreach ($r in $grid.SelectedRows) {
            $sessId = [int]$r.Cells["ID"].Value
            $broker = $r.Cells["BrokerHost"].Value
            try {
                Send-RDUserMessage -ConnectionBroker $broker -UnifiedSessionId $sessId -MessageTitle "Сообщение от Администратора" -MessageBody $msg
            } catch {}
        }
    }
}
$btnMsg.Add_Click($DoSendMessage)
$miSendMsg.Add_Click($DoSendMessage)

$miCopyUser.Add_Click({
    if ($grid.SelectedRows.Count -gt 0) {
        $r = $grid.SelectedRows[0]
        $txt = "$($r.Cells['ФИО (AD)'].Value) ($($r.Cells['Логин'].Value)) — $($r.Cells['Сервер RDSH'].Value)"
        [System.Windows.Forms.Clipboard]::SetText($txt)
    }
})

$miOpenC.Add_Click({
    if ($grid.SelectedRows.Count -gt 0) {
        $hostServer = $grid.SelectedRows[0].Cells["HostServerFQDN"].Value
        Start-Process "explorer.exe" -ArgumentList "\\$hostServer\c$"
    }
})

$btnExport.Add_Click({
    if (-not $script:table -or $script:table.DefaultView.Count -eq 0) { return }
    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "CSV файл (*.csv)|*.csv"
    $sfd.FileName = "RDS_Sessions_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').csv"
    if ($sfd.ShowDialog() -eq "OK") {
        $lines = @("Ферма;IP брокера;Логин;ФИО;Отдел;Сервер RDSH;Статус;ID;Время входа;Простой (мин)")
        foreach ($drv in $script:table.DefaultView) {
            $lines += "$($drv['Ферма']);$($drv['IP брокера']);$($drv['Логин']);$($drv['ФИО (AD)']);$($drv['Отдел / Должность']);$($drv['Сервер RDSH']);$($drv['Статус']);$($drv['ID']);$($drv['Время входа']);$($drv['Простой (мин)'])"
        }
        $lines | Set-Content -Path $sfd.FileName -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Отчет сохранен:`n$($sfd.FileName)", "Экспорт CSV", "OK", "Information")
    }
})

$grid.Add_CellDoubleClick({
    param($sender, $e)
    if ($e.RowIndex -ge 0) { Start-SilentShadow $true }
})

$form.Add_KeyDown({
    param($sender, $e)
    if ($e.KeyCode -eq "F5") { & $StartLoadSessions }
})

$form.Add_FormClosing({
    $script:timer.Stop()
    $script:autoTimer.Stop()
    if ($script:runspacePool) {
        $script:runspacePool.Close()
        $script:runspacePool.Dispose()
    }
})

# При первом запуске (если список брокеров пуст) сразу открываем окно настроек инфраструктуры
$form.Add_Shown({
    if ($script:candidateBrokers.Count -eq 0) {
        & $ShowSettingsDialog
    } else {
        & $StartLoadSessions
    }
})

[void]$form.ShowDialog()
