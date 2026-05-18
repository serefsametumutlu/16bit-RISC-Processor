import os
import glob
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

# =========================================================
# IMPORT SIMULATOR
# =========================================================
# Asıl işlem yapan CPU, assembler ve yardımcı fonksiyonlar buradan geliyor
from simulator import Processor, load_assembly_file, assemble_program_with_labels


class SimulatorGUI(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("16-Bit RISC Pipeline Simulator")
        self.geometry("1400x850")

        self._apply_modern_theme()

        self.cpu = None
        self.loaded_program_path = None
        self.code_tuples = []
        self.running = False

        self._build_ui()
        self._refresh_test_list()
        self._reset_cpu()

    def _apply_modern_theme(self):
        # Arayüz için koyu tema ayarları
        style = ttk.Style(self)
        try:
            style.theme_use('clam')
        except:
            pass

        bg_dark = "#2b2b2b"
        bg_lighter = "#3c3f41"
        fg_white = "#ffffff"
        accent_blue = "#4a90e2"

        self.configure(bg=bg_dark)

        style.configure("TFrame", background=bg_dark)
        style.configure("TLabel", background=bg_dark, foreground=fg_white, font=("Segoe UI", 10))
        style.configure("TLabelframe", background=bg_dark, foreground=accent_blue)
        style.configure("TLabelframe.Label", background=bg_dark, foreground=accent_blue, font=("Segoe UI", 11, "bold"))

        style.configure(
            "TButton",
            font=("Segoe UI", 10, "bold"),
            background=bg_lighter,
            foreground="white",
            borderwidth=1,
            focuscolor=accent_blue
        )
        style.map("TButton", background=[("active", accent_blue), ("pressed", "#357abd")])

        style.configure("Run.TButton", foreground="white", background="#218c74")
        style.map("Run.TButton", background=[("active", "#33d9b2")])

        style.configure("TCombobox", fieldbackground=bg_lighter, background=accent_blue, foreground="black")
        style.configure("TSpinbox", fieldbackground=bg_lighter, foreground="black")

        style.configure(
            "Treeview",
            background=bg_lighter,
            foreground=fg_white,
            fieldbackground=bg_lighter,
            font=("Consolas", 10),
            rowheight=25
        )
        style.configure("Treeview.Heading", background="#1e1e1e", foreground="#dfe6e9", font=("Segoe UI", 10, "bold"))
        style.map("Treeview", background=[("selected", accent_blue)])

    # ---------------- UI CONSTRUCTION ----------------
    def _build_ui(self):
        # Ana pencere düzeni
        self.columnconfigure(0, weight=1)
        self.rowconfigure(0, weight=1)

        main_frame = ttk.Frame(self, padding=15)
        main_frame.grid(row=0, column=0, sticky="nsew")

        main_frame.rowconfigure(1, weight=1)
        main_frame.columnconfigure(0, weight=3)
        main_frame.columnconfigure(1, weight=2)

        # ================= TOP BAR =================
        # Üst kısım: dosya seçme, çalıştırma ve kontrol butonları
        top_bar = ttk.Frame(main_frame)
        top_bar.grid(row=0, column=0, columnspan=2, sticky="ew", pady=(0, 15))

        ttk.Label(top_bar, text="📁 Test File:").pack(side="left", padx=(0, 5))

        self.test_var = tk.StringVar()
        self.test_combo = ttk.Combobox(top_bar, textvariable=self.test_var, state="readonly", width=30)
        self.test_combo.pack(side="left", padx=(0, 5))
        self.test_combo.bind("<<ComboboxSelected>>", lambda e: self.on_select_test())

        ttk.Button(top_bar, text="🔄", width=3, command=self._refresh_test_list, cursor="hand2").pack(side="left", padx=(0, 5))
        ttk.Button(top_bar, text="Browse...", command=self.browse_asm, cursor="hand2").pack(side="left", padx=(0, 15))

        ttk.Button(top_bar, text="⬇ LOAD", command=self.load_selected_program, cursor="hand2").pack(side="left", padx=(0, 5))
        ttk.Button(top_bar, text="⏹ RESET", command=self._reset_cpu, cursor="hand2").pack(side="left", padx=(0, 5))

        ttk.Separator(top_bar, orient="vertical").pack(side="left", fill="y", padx=10)

        ttk.Button(top_bar, text="👣 Step", command=self.step_once, cursor="hand2").pack(side="left", padx=(0, 5))

        self.run_btn = ttk.Button(top_bar, text="▶ RUN", style="Run.TButton", command=self.toggle_run, cursor="hand2")
        self.run_btn.pack(side="left", padx=(0, 15))

        ttk.Label(top_bar, text="Max Cycle:").pack(side="left")
        self.max_cycles_var = tk.IntVar(value=150)
        ttk.Spinbox(top_bar, from_=1, to=5000, textvariable=self.max_cycles_var, width=5).pack(side="left", padx=(5, 20))

        # Sağ üstte cycle ve PC bilgisini gösterir
        self.cycle_pc_var = tk.StringVar(value="CYCLE 0   PC 0")
        ttk.Label(top_bar, textvariable=self.cycle_pc_var, font=("Segoe UI", 11, "bold")).pack(side="right")

        # ================= LEFT PANEL =================
        left_panel = ttk.Frame(main_frame)
        left_panel.grid(row=1, column=0, sticky="nsew", padx=(0, 10))
        left_panel.columnconfigure(0, weight=1)
        left_panel.rowconfigure(2, weight=1)

        # -------- Assembly & Machine Code Preview --------
        # Seçilen dosyanın satır satır makine koduna çevrilmiş hali
        prev_frame = ttk.LabelFrame(left_panel, text=" Assembly & Machine Code Preview ", padding=10)
        prev_frame.grid(row=0, column=0, sticky="ew", pady=(0, 10))

        self.preview = tk.Text(
            prev_frame, height=10, width=50, wrap="none",
            bg="#1e1e1e", fg="#eef1ee", insertbackground="white",
            font=("Consolas", 10)
        )
        prev_scroll = ttk.Scrollbar(prev_frame, orient="vertical", command=self.preview.yview)
        self.preview.configure(yscrollcommand=prev_scroll.set)

        self.preview.pack(side="left", fill="both", expand=True)
        prev_scroll.pack(side="right", fill="y")
        self.preview.configure(state="disabled")

        # -------- Pipeline Visualizer --------
        # IF / ID / EX / MEM / WB anlık durumları
        vis_frame = ttk.LabelFrame(left_panel, text=" Pipeline Visualizer ", padding=10)
        vis_frame.grid(row=1, column=0, sticky="ew", pady=(0, 10))
        vis_frame.columnconfigure(tuple(range(5)), weight=1)

        self.stage_labels = {}
        stages = [
            ("IF",  "#4a86e8"),
            ("ID",  "#cc3d3d"),
            ("EX",  "#2ea44f"),
            ("MEM", "#c49a1a"),
            ("WB",  "#7a4dc9"),
        ]

        for i, (name, color) in enumerate(stages):
            box = tk.Frame(vis_frame, bg=color, bd=0, highlightthickness=0)
            box.grid(row=0, column=i, sticky="ew", padx=6, pady=2)
            box.grid_propagate(False)
            box.configure(height=70)

            title = tk.Label(box, text=name, bg=color, fg="white", font=("Segoe UI", 11, "bold"))
            title.pack(side="top", pady=(6, 2))

            val = tk.Label(box, text="-", bg=color, fg="white", font=("Consolas", 10, "bold"))
            val.pack(side="top", pady=(6, 6))

            self.stage_labels[name] = val

        # -------- Pipeline Timeline --------
        # Her cycle için IF–WB durumlarını tablo halinde gösterir
        pipe_frame = ttk.LabelFrame(left_panel, text=" Pipeline Timeline Diagram ", padding=10)
        pipe_frame.grid(row=2, column=0, sticky="nsew")
        pipe_frame.rowconfigure(0, weight=1)
        pipe_frame.columnconfigure(0, weight=1)

        cols = ("CYCLE", "IF", "ID", "EX", "MEM", "WB")
        self.pipe_tree = ttk.Treeview(pipe_frame, columns=cols, show="headings", selectmode="browse")

        self.pipe_tree.heading("CYCLE", text="CYC")
        self.pipe_tree.column("CYCLE", width=50, anchor="center", stretch=False)

        for c in cols[1:]:
            self.pipe_tree.heading(c, text=c)
            self.pipe_tree.column(c, width=250, anchor="center")

        pipe_vscroll = ttk.Scrollbar(pipe_frame, orient="vertical", command=self.pipe_tree.yview)
        pipe_hscroll = ttk.Scrollbar(pipe_frame, orient="horizontal", command=self.pipe_tree.xview)

        self.pipe_tree.configure(yscrollcommand=pipe_vscroll.set, xscrollcommand=pipe_hscroll.set)

        self.pipe_tree.grid(row=0, column=0, sticky="nsew")
        pipe_vscroll.grid(row=0, column=1, sticky="ns")
        pipe_hscroll.grid(row=1, column=0, sticky="ew")

        self.pipe_tree.tag_configure('odd', background='#3c3f41')
        self.pipe_tree.tag_configure('even', background='#45484a')

        # ================= RIGHT PANEL =================
        right_panel = ttk.Frame(main_frame)
        right_panel.grid(row=1, column=1, sticky="nsew")
        right_panel.rowconfigure(2, weight=1)
        right_panel.columnconfigure(0, weight=1)

        # -------- Register File --------
        # Register içeriklerini anlık gösterir
        reg_frame = ttk.LabelFrame(right_panel, text=" Register File ", padding=10)
        reg_frame.grid(row=0, column=0, sticky="ew", pady=(0, 10))

        self.reg_tree = ttk.Treeview(reg_frame, columns=("REG", "HEX", "DEC"), show="headings", height=8)
        self.reg_tree.heading("REG", text="Reg")
        self.reg_tree.column("REG", width=60, anchor="center")
        self.reg_tree.heading("HEX", text="Hex Value")
        self.reg_tree.column("HEX", width=100, anchor="center")
        self.reg_tree.heading("DEC", text="Dec Value")
        self.reg_tree.column("DEC", width=100, anchor="center")

        self.reg_tree.pack(fill="x", expand=True)
        self.reg_tree.tag_configure('odd', background='#3c3f41')
        self.reg_tree.tag_configure('even', background='#45484a')

        # -------- Memory Dump --------
        # Data memory içeriğini kelime bazında gösterir
        mem_frame = ttk.LabelFrame(right_panel, text=" Data Memory Dump ", padding=10)
        mem_frame.grid(row=1, column=0, sticky="ew", pady=(0, 10))

        mem_ctrl = ttk.Frame(mem_frame)
        mem_ctrl.pack(fill="x", pady=(0, 5))

        ttk.Label(mem_ctrl, text="Start Index:").pack(side="left")
        self.mem_start_var = tk.IntVar(value=0)
        ttk.Spinbox(mem_ctrl, from_=0, to=255, textvariable=self.mem_start_var, width=5).pack(side="left", padx=5)

        ttk.Label(mem_ctrl, text="Count:").pack(side="left", padx=(10, 0))
        self.mem_count_var = tk.IntVar(value=16)
        ttk.Spinbox(mem_ctrl, from_=1, to=256, textvariable=self.mem_count_var, width=5).pack(side="left", padx=5)

        ttk.Button(mem_ctrl, text="View", command=self.refresh_views).pack(side="right")

        self.mem_tree = ttk.Treeview(mem_frame, columns=("WORD", "BYTE", "HEX", "DEC"), show="headings", height=8)

        headers = [("WORD", "Word Idx", 70), ("BYTE", "Byte Addr", 80), ("HEX", "Hex", 100), ("DEC", "Decimal", 100)]
        for col, title, w in headers:
            self.mem_tree.heading(col, text=title)
            self.mem_tree.column(col, width=w, anchor="center")

        self.mem_tree.pack(fill="x", expand=True)
        self.mem_tree.tag_configure('odd', background='#3c3f41')
        self.mem_tree.tag_configure('even', background='#45484a')

        # -------- System Log --------
        # Program sırasında oluşan mesajlar burada görünür
        log_frame = ttk.LabelFrame(right_panel, text=" System Log ", padding=10)
        log_frame.grid(row=2, column=0, sticky="nsew")

        self.log_text = tk.Text(log_frame, wrap="word", height=8, bg="#1e1e1e", fg="#dcdcdc", font=("Consolas", 9))
        log_scroll = ttk.Scrollbar(log_frame, orient="vertical", command=self.log_text.yview)
        self.log_text.configure(yscrollcommand=log_scroll.set)

        self.log_text.pack(side="left", fill="both", expand=True)
        log_scroll.pack(side="right", fill="y")
        self.log_text.configure(state="disabled")

    # ---------------- FUNCTIONS ----------------
    def log(self, msg: str):
        # Log alanına mesaj basar
        self.log_text.configure(state="normal")
        self.log_text.insert("end", f">> {msg}\n")
        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    def _refresh_test_list(self):
        # tests klasöründeki asm dosyalarını listele
        tests_dir = os.path.join(os.getcwd(), "tests")
        os.makedirs(tests_dir, exist_ok=True)
        paths = sorted(glob.glob(os.path.join(tests_dir, "*.asm")))
        self.test_map = {os.path.basename(p): p for p in paths}
        self.test_combo["values"] = list(self.test_map.keys())
        if self.test_map and self.test_var.get() not in self.test_map:
            self.test_var.set(list(self.test_map.keys())[0])
        self.log(f"Test folder scanned: {len(paths)} files found.")

    def on_select_test(self):
        # Combobox’tan dosya seçilince preview güncellenir
        name = self.test_var.get()
        path = self.test_map.get(name)
        if path:
            self.loaded_program_path = path
            self._preview_program(path)

    def browse_asm(self):
        # Dışarıdan .asm dosyası seçmek için
        p = filedialog.askopenfilename(title="Select ASM File", filetypes=[("Assembly", "*.asm"), ("All files", "*.*")])
        if p:
            self.loaded_program_path = p
            self.test_var.set(os.path.basename(p))
            self.log(f"File selected: {p}")
            self._preview_program(p)

    def _preview_program(self, filepath):
        # Assembly → makine kodu önizleme
        try:
            lines = load_assembly_file(filepath)
            if not lines:
                self._set_preview_text("File empty or unreadable.")
                return

            code_tuples = assemble_program_with_labels(lines)
            out = []
            bad = 0
            for a in code_tuples:
                mc = a.machineCode & 0xFFFF
                if mc == 0x0000:
                    bad += 1
                out.append(f"{a.source:<30} | 0x{mc:04X} | {mc:016b}")

            if bad:
                out.append(f"\n[WARN] {bad} lines compiled as 0x0000 (NOP/Invalid).")
            self._set_preview_text("\n".join(out))
        except Exception as e:
            messagebox.showerror("Error", str(e))

    def _set_preview_text(self, text):
        self.preview.configure(state="normal")
        self.preview.delete("1.0", "end")
        self.preview.insert("1.0", text)
        self.preview.configure(state="disabled")

    def _reset_cpu(self):
        # Simülatörü baştan başlatır
        self.running = False
        self.run_btn.configure(text="▶ RUN", style="Run.TButton")
        self.cpu = Processor()
        self.code_tuples = []

        for t in (self.pipe_tree, self.reg_tree, self.mem_tree):
            for item in t.get_children():
                t.delete(item)

        self._set_preview_text("")
        self.log("CPU and Memory reset. Ready to load new test.")
        self.refresh_views()
        self._refresh_header_and_visualizer()

    def load_selected_program(self):
        # Seçilen asm dosyasını CPU’ya yükler
        if not self.loaded_program_path:
            messagebox.showwarning("Warning", "Please select a test file first.")
            return

        try:
            lines = load_assembly_file(self.loaded_program_path)
            self.cpu = Processor()
            code_tuples = assemble_program_with_labels(lines)
            self.code_tuples = code_tuples
            self.cpu.load_program(code_tuples)

            self.log(f"PROGRAM LOADED: {len(code_tuples)} instructions.")
            self.refresh_views()
            self._refresh_header_and_visualizer()
        except Exception as e:
            self.log(f"ERROR: {e}")

    def step_once(self):
        # Tek clock cycle ilerletir
        if not self.code_tuples:
            messagebox.showwarning("Warning", "No program loaded.")
            return
        try:
            self.cpu.run_cycle()
            self._append_pipeline_row()
            self.refresh_views()
            self._refresh_header_and_visualizer()
            self._auto_stop_if_done()
        except Exception as e:
            self.log(f"Execution Error: {e}")

    def toggle_run(self):
        # Sürekli çalıştır / durdur
        if self.running:
            self.running = False
            self.run_btn.configure(text="▶ RESUME")
            self.log("Simulation paused.")
        else:
            if not self.code_tuples:
                messagebox.showwarning("Warning", "No program loaded.")
                return
            self.running = True
            self.run_btn.configure(text="⏸ PAUSE")
            self.log("Simulation started...")
            self._run_loop(self.max_cycles_var.get())

    def _run_loop(self, budget):
        # Otomatik cycle çalıştırma döngüsü
        if not self.running:
            return
        if budget <= 0:
            self.running = False
            self.run_btn.configure(text="▶ RUN")
            self.log("Max cycle limit reached.")
            return

        try:
            self.cpu.run_cycle()
            self._append_pipeline_row()
            self.refresh_views()
            self._refresh_header_and_visualizer()

            if self._auto_stop_if_done():
                return

            self.after(50, lambda: self._run_loop(budget - 1))
        except Exception as e:
            self.running = False
            self.log(f"Error: {e}")

    def _auto_stop_if_done(self):
        # Program tamamen bittiyse otomatik dur
        try:
            is_if_end = (self.cpu.pipe_view.get("IF") == "END")
            is_empty = (not self.cpu.id_ex) and (not self.cpu.ex_mem) and (not self.cpu.mem_wb)
            if is_if_end and is_empty and not self.cpu.stall:
                self.running = False
                self.run_btn.configure(text="▶ RE-RUN")
                self.log("--- PROGRAM FINISHED (Pipeline Drained) ---")
                return True
        except:
            pass
        return False

    def _append_pipeline_row(self):
        # Timeline tablosuna yeni cycle satırı ekler
        cyc = getattr(self.cpu, "cycle_count", 0)
        pv = self.cpu.pipe_view
        row = (
            str(cyc),
            str(pv.get("IF", "-")),
            str(pv.get("ID", "-")),
            str(pv.get("EX", "-")),
            str(pv.get("MEM", "-")),
            str(pv.get("WB", "-")),
        )
        tag = 'even' if cyc % 2 == 0 else 'odd'
        self.pipe_tree.insert("", "end", values=row, tags=(tag,))
        self.pipe_tree.yview_moveto(1)

    def _refresh_header_and_visualizer(self):
        # Üstteki cycle / PC göstergesi ve pipeline kutuları güncellenir
        if not self.cpu:
            self.cycle_pc_var.set("CYCLE 0   PC 0")
            for k in self.stage_labels:
                self.stage_labels[k].configure(text="-")
            return

        cyc = int(getattr(self.cpu, "cycle_count", 0))
        pc = int(getattr(self.cpu, "pc", 0))
        self.cycle_pc_var.set(f"CYCLE {cyc}   PC {pc}")

        pv = self.cpu.pipe_view
        for stage in ["IF", "ID", "EX", "MEM", "WB"]:
            txt = str(pv.get(stage, "-"))
            if len(txt) > 40:
                txt = txt[:38] + "…"
            self.stage_labels[stage].configure(text=txt)

    def refresh_views(self):
        # Register ve memory tablolarını günceller
        for item in self.reg_tree.get_children():
            self.reg_tree.delete(item)

        regs = self.cpu.reg_file.regs if self.cpu else [0] * 8
        for i, val in enumerate(regs):
            v = int(val) & 0xFFFF
            tag = 'even' if i % 2 == 0 else 'odd'
            self.reg_tree.insert("", "end", values=(f"R{i}", f"0x{v:04X}", str(v)), tags=(tag,))

        for item in self.mem_tree.get_children():
            self.mem_tree.delete(item)

        if self.cpu:
            start = self.mem_start_var.get()
            count = self.mem_count_var.get()
            for i, w in enumerate(range(start, min(start + count, 256))):
                byte_addr = w * 2
                val = self.cpu.data_mem.read_word(byte_addr) & 0xFFFF
                tag = 'even' if i % 2 == 0 else 'odd'
                self.mem_tree.insert("", "end", values=(w, byte_addr, f"0x{val:04X}", str(val)), tags=(tag,))


if __name__ == "__main__":
    app = SimulatorGUI()
    app.mainloop()