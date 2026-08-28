# SolvForge

SolvForge 是一个面向 MOF、COF、沸石、slab 和复杂表面体系的 Windows x64 溶剂/电解液构型生成器。

它的目标很直接：给定一个材料结构和一个或多个 PDB 分子模板，在材料的周期性自由体积中生成几何上合理、可继续用于后续模拟准备的溶剂化结构。

当前发布包为 Windows x64 便携版，不需要安装 Python、.NET、GROMACS 或 Packmol。下载并解压后，双击 `SolvForge-GUI.cmd` 即可启动图形界面。

> **使用限制：** SolvForge 采用自定义限制性许可，仅允许非商业学术研究、教学和内部科研验证。禁止商业使用、任何未经授权的代算或第三方计算服务、未经授权的二次开发、修改、反向工程、再分发和重新包装。完整条款见 [`LICENSE.md`](LICENSE.md)。

## 1. SolvForge 解决了什么问题？

Packmol 等通用分子装配工具可以按照用户定义的盒子、球体或其他区域放置分子，但对于“从真实材料晶胞自动识别自由体积，再把溶剂放入非规则表面和周期性孔道”的完整流程，往往还需要用户自己编写脚本并拼接多个工具。特别是沟壑、台阶、粗糙 slab、带真空层的表面，以及具有复杂孔道网络的 MOF、COF 和沸石，缺少一个面向这一类材料结构的直接解决方案。

SolvForge 填补的正是这个空白：它把材料晶胞解析、自由体积识别、周期性处理、随机分子放置和结构输出整合成一个独立工具。用户只需要提供材料结构和 PDB 分子模板，就可以直接生成非规则表面或孔道中的溶剂化结构。

为了可靠地完成这一流程，SolvForge 同时实现了以下关键能力：

- 用材料晶胞建立自由体积和周期性边界；
- 根据材料类型处理 slab 的 XY 周期和 Z 方向真空层，或三维孔道的 XYZ 周期；
- 采用连续随机平移和随机旋转放置分子，而不是把最终分子中心锁在规则网格上；
- 使用原子级距离检查、空间分桶和周期性最小镜像距离避免重叠；
- 支持单组分和多组分溶液；
- GRO 输出保留 PDB 中的显式虚原子，水模板缺少虚原子时自动切换到带虚原子的对应水模型；
- 允许用户自主选择 GRO 或 CIF 输出；
- 输出完成后保留图形界面，命令行直接运行时也会等待用户确认后再关闭。

> SolvForge 负责生成结构坐标，不负责自动生成拓扑、电荷、键角参数或完成 MD 平衡。正式分子动力学计算前，仍需根据所选力场补充对应的拓扑和参数。

## 2. 工作原理

SolvForge 的核心流程可以概括为：

```text
材料结构 + 晶胞
        ↓
解析周期性和自由体积
        ↓
生成可用候选区域
        ↓
随机平移 + 随机旋转生成分子候选
        ↓
周期性原子级重叠检查
        ↓
随机顺序插入与迭代精修
        ↓
输出 GRO 或 CIF 结构文件
```

### 2.1 自由体积识别

程序从材料 CIF、POSCAR 或内置材料库读取原子坐标和晶胞，构建自由体积场。候选区域会同时考虑材料原子的排斥距离、溶剂分子的空间尺寸、用户设置的材料-溶剂最小距离、分子之间的最小安全距离，以及指定的周期方向和填充范围。

### 2.2 周期性处理

- 对 slab、沟壑、台阶和粗糙表面，默认 Z 轴为真空层，主要使用 XY 周期分布；
- 对三维 MOF、COF 和沸石孔道，默认使用 XYZ 周期分布；
- 也可以通过 GUI 或 `--periodic` 手动指定周期方向；
- 碰撞检查使用周期性最小镜像距离，避免分子跨晶胞边界时发生隐性重叠。

### 2.3 随机插入算法

网格只用于快速定位自由空间，并不决定最终分子中心。每个候选分子会经过连续随机平移、均匀随机空间旋转、材料原子级距离检查、已放置分子周期性距离检查，以及接受/拒绝和有限次数的随机迭代精修。

这种方法借鉴 Packmol 的随机顺序添加思想，但针对周期性材料自由体积进行了专门处理。它可以减少规则网格造成的条纹、层状和棋盘式分布，同时保留随机种子控制带来的可重复性。

### 2.4 虚原子和输出文件

GRO 模式下，程序会保留输入 PDB 中的显式虚原子：TIP4P-Ew 使用 `MW`，TIP5P 使用 `LP1`/`LP2`，OPC 使用 `MW`。如果水 PDB 只有 O/H 实体原子，程序会自动换用带显式虚原子的对应模板，并在报告文件中记录替换情况。

GRO 文件只保存结构坐标、残基/原子名称和晶胞信息，不包含拓扑和电荷；同时也可以输出 CIF 作为结构检查副本或独立主输出。

## 3. 支持的模型

### 3.1 材料结构模型

| 模型类型 | 典型体系 | 默认周期方向 |
|---|---|---|
| `surface` | slab、平面、沟壑、台阶、粗糙表面、真空层 | XY |
| `pore` | 三维 MOF、COF、沸石孔道 | XYZ |
| `accessible` | 所有满足几何间隙要求的自由空间 | 由晶胞和参数决定 |
| `ion` | 只插入离子或进行离子空间保护 | 由模型和参数决定 |

输入结构主要支持 CIF、POSCAR/VASP 结构、带 `--cell A B C` 晶胞参数的 XYZ，以及程序包内置的材料 CIF。

### 3.2 水模型

| 水模型 | 模板 | 虚原子情况 |
|---|---|---|
| TIP3P | `water_tip3p.pdb` | 三个实体原子 |
| SPC | `water_spc.pdb` | 三个实体原子 |
| SPC/E | `water_spce.pdb` | 三个实体原子 |
| TIP4P-Ew | `water_tip4pew.pdb` | 显式 `MW` |
| TIP5P | `water_tip5p.pdb` | 显式 `LP1`、`LP2` |
| OPC | `water_opc.pdb` | 显式 `MW` |

输出 GRO 时，如果使用没有虚原子的水 PDB，程序会自动升级到带显式虚原子的对应水模板；输出 CIF 时则保留用户指定模板的原子组成。

### 3.3 电解液和常用分子模型

内置 PDB 模板包括 EC、PC、DMC、DEC、EMC、ACN、DME、THF、DMSO、DMF、甲醇和乙醇；阳离子包括 Li⁺、Na⁺、K⁺、Mg²⁺、Ca²⁺、Zn²⁺；阴离子包括 Cl⁻、F⁻、PF₆⁻、SO₄²⁻、BF₄⁻、ClO₄⁻、FSI⁻、TFSI⁻。

多组分体系可以通过 GUI 填写数量或比例，也可以使用 TSV 文件描述组成，例如 EC/DMC/LiPF6 电解液或水/ZnSO4 溶液。

## 4. 软件自带的材料库

当前发布包的 `templates/materials/` 目录包含约 206 个材料 CIF，按来源和结构类型组织：

| 材料类别 | 数量 | 目录 |
|---|---:|---|
| MOF | 108 | `templates/materials/raspa2/mofs/cif/` |
| 沸石 | 54 | `templates/materials/raspa2/zeolites/cif/` |
| 陶瓷、石墨和碳材料 | 38 | `templates/materials/raspa2/ceramics/cif/` |
| 矿物 | 3 | `templates/materials/raspa2/minerals/cif/` |
| 精选示例 | 3 | `templates/materials/` |

代表性结构包括 MOF-5/IRMOF-1、IRMOF-10、MOF-74、MIL、ZIF、UiO-66、PCN、NU 系列，COF-1、COF-5、COF-102、COF-105、COF-300，LTA、FAU、MFI、BEA、CHA、AFI 等沸石，以及石墨、碳片层和其他碳材料模型。

发布包还提供 `examples/rugged_slab_demo.cif`、水/ZnSO₄ 配比文件和 EC/DMC/LiPF₆ 配比文件，用于快速验证异型表面和多组分电解液。

可以使用以下命令查看当前安装包中的全部材料和溶剂模板：

```powershell
solvforge.exe --list-materials
solvforge.exe --list-solvents
```

材料库中部分结构来自 RASPA2 公共示例、IZA 沸石结构数据库或精选 COF 条目；相关说明和许可文件随发布包保存在对应目录中。正式研究使用前，建议检查晶胞、原子坐标、周期性和结构来源是否满足具体计算需求。

## 5. 快速开始

1. 下载并完整解压 GitHub Release ZIP；
2. 双击 `SolvForge-GUI.cmd`；
3. 选择材料 CIF/POSCAR；
4. 添加一个或多个 PDB 溶剂/离子模板；
5. 选择数量、密度、周期方向和 GRO/CIF 输出格式；
6. 点击生成。

命令行示例：

```powershell
solvforge.exe --material material.cif --solvent water_tip4pew --number 200 --output filled.gro
solvforge.exe --material IRMOF-10 --solvent water_tip4pew --number 100 --mode pore --periodic xyz --output mof_water.gro
solvforge.exe --material slab.cif --solvent water_tip4pew --number 200 --mode surface --periodic xy --output slab_water.gro
```

## 6. 输出和限制

程序可输出 `.gro` 或 `.cif`，并生成 `.report.json` 和自由体积 `.cube` 数据。GRO 与 CIF 都是结构文件，不是完整的 MD 输入；进行 GROMACS、LAMMPS 或其他分子动力学计算前，需要根据力场补充拓扑、电荷、质量、键、角度和非键参数，并进行能量最小化和预平衡。

当前公开便携包面向 Windows x64；Linux、macOS 和 ARM 版本需要单独构建。对极窄孔道、严重重叠、异常晶胞或不完整 CIF，可能无法达到目标分子数量，此时应查看报告文件并调整数量、距离或晶胞。

## 联系方式

开发者微信：`x1aohua501`
