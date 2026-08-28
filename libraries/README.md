# 结构库与模板库

程序包内置了常用示例，以及 RASPA2 `structures` 目录中的 203 个 CIF 结构；更大的 MOF/COF 数据库仍采用外部库索引方式，以避免数 GB/数百 GB 的体积和数据库授权问题。

本程序的迭代插入器是独立实现的原生 C# 轻量优化器：将距离约束和空间约束写入非负目标函数，采用较宽初始容差、逐步收紧容差，并把拥挤分子随机重定位到更好的自由体积候选位置。

## 已内置的 RASPA2 结构

`templates/materials/raspa2/` 下包含：

- 108 个 MOF 结构；
- 54 个沸石结构；
- 38 个陶瓷/碳材料结构；
- 3 个矿物结构。

原始目录来自 [numat/RASPA2 structures](https://github.com/numat/RASPA2/tree/master/structures)，并随包附带其 MIT 许可证副本 `libraries/RASPA2-COPYING.txt`。Windows 下保留设备名 `CON.cif` 时改名为 `CON_structure.cif`，结构内容不变。

## 推荐来源

- MOF：CoRE-MOF 2014/2019。公开部分可从 Zenodo 获取，CoRE-MOF 2019 public 数据按 CC BY 4.0 发布：[Zenodo 数据集](https://zenodo.org/records/3370236)、[CoRE-MOF 工具说明](https://github.com/coudertlab/CoRE-MOF)。
- MOF：MOFX-DB，提供 CoREMOF 2014/2019 和 hMOF 等批量 CIF 入口：[MOFX-DB databases](https://mof.tech.northwestern.edu/databases)。
- COF：CURATED-COFs，包含实验 COF 的 CIF、结构清洗记录和论文索引：[CURATED-COFs](https://github.com/danieleongari/CURATED-COFs)。
- 沸石：IZA Structure Database，提供已确认框架类型、CIF、孔道、环结构和可访问体积信息：[IZA Database](https://www.iza-structure.org/databases/)。
- 开放晶体结构：COD，包含有机、无机和金属有机结构，数据采用 CC0：[Crystallography Open Database](https://qiserver.ugr.es/cod/)。
- 更大规模的预测 COF/MOF 数据集应按其各自的下载和许可证条款获取，不在本程序包中默认镜像。

## 内置材料示例

`templates/materials/` 中保留小型示例。用户也可以直接将任意 CIF 放入自己的项目目录，然后运行：

```powershell
solvforge.exe --material my_structure.cif --solvent water_tip3p --output my_structure_water.cif
```

结构库中的 CIF 往往是“不对称单元 + 空间群操作”格式。程序会尝试展开常见的空间群操作，并支持一般非正交晶胞；对于含无序、部分占位或复杂特殊位置的结构，仍建议先用 VESTA/ASE/pymatgen 检查和规整。
