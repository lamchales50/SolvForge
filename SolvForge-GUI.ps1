Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Xaml

$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $baseDir 'solvforge.exe'
$script:process = $null
$script:stdoutPath = $null
$script:stderrPath = $null
$script:stdoutLength = 0
$script:stderrLength = 0

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
 Title="SolvForge · 溶剂/电解液构型生成器" Width="1160" Height="780" MinWidth="980" MinHeight="680"
 WindowStartupLocation="CenterScreen" Background="#F5F7FB" FontFamily="Microsoft YaHei UI">
 <Window.Resources>
  <SolidColorBrush x:Key="Ink" Color="#172033"/><SolidColorBrush x:Key="Muted" Color="#68758B"/>
  <SolidColorBrush x:Key="Line" Color="#E2E7F0"/><SolidColorBrush x:Key="Blue" Color="#2563EB"/>
  <SolidColorBrush x:Key="BlueLight" Color="#EAF1FF"/><SolidColorBrush x:Key="Panel" Color="#FFFFFF"/>
  <Style TargetType="TextBlock"><Setter Property="Foreground" Value="{StaticResource Ink}"/></Style>
  <Style TargetType="Label"><Setter Property="Foreground" Value="{StaticResource Muted}"/><Setter Property="FontSize" Value="13"/><Setter Property="Padding" Value="0,0,0,4"/></Style>
  <Style TargetType="TextBox"><Setter Property="FontSize" Value="14"/><Setter Property="Padding" Value="9,6"/><Setter Property="BorderBrush" Value="#D7DEEA"/><Setter Property="Background" Value="White"/><Setter Property="VerticalContentAlignment" Value="Center"/></Style>
  <Style TargetType="ComboBox"><Setter Property="FontSize" Value="14"/><Setter Property="Padding" Value="8,5"/><Setter Property="BorderBrush" Value="#D7DEEA"/><Setter Property="Background" Value="White"/><Setter Property="MinHeight" Value="36"/></Style>
  <Style TargetType="Button"><Setter Property="FontSize" Value="14"/><Setter Property="Padding" Value="14,7"/><Setter Property="Margin" Value="0,0,8,0"/><Setter Property="Background" Value="White"/><Setter Property="BorderBrush" Value="#D7DEEA"/><Setter Property="Cursor" Value="Hand"/></Style>
  <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}"><Setter Property="Background" Value="{StaticResource Blue}"/><Setter Property="Foreground" Value="White"/><Setter Property="BorderBrush" Value="{StaticResource Blue}"/><Setter Property="FontWeight" Value="SemiBold"/><Setter Property="Padding" Value="22,10"/></Style>
  <Style x:Key="SoftButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}"><Setter Property="Background" Value="{StaticResource BlueLight}"/><Setter Property="Foreground" Value="{StaticResource Blue}"/><Setter Property="BorderBrush" Value="#D7E4FF"/></Style>
  <Style TargetType="GroupBox"><Setter Property="Margin" Value="0,0,0,10"/><Setter Property="Padding" Value="13,10,13,12"/><Setter Property="BorderBrush" Value="{StaticResource Line}"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Background" Value="{StaticResource Panel}"/><Setter Property="Foreground" Value="{StaticResource Ink}"/><Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/></Style>
 </Window.Resources>
 <Grid>
  <Grid.RowDefinitions><RowDefinition Height="84"/><RowDefinition Height="*"/><RowDefinition Height="56"/></Grid.RowDefinitions>
  <Border Grid.Row="0" Background="#172033" Padding="28,16"><Grid>
   <StackPanel VerticalAlignment="Center"><TextBlock Text="SolvForge" Foreground="White" FontSize="25" FontWeight="Bold"/><TextBlock Text="材料孔道与表面溶剂自动填充" Foreground="#B6C2D6" FontSize="13" Margin="1,4,0,0"/></StackPanel>
   <Border HorizontalAlignment="Right" VerticalAlignment="Center" Background="#25324A" CornerRadius="18" Padding="13,7"><TextBlock Text="GUI 工作台" Foreground="#D6E4FF" FontSize="13"/></Border>
  </Grid></Border>
  <Grid Grid.Row="1" Margin="24,20,24,14">
   <Grid.ColumnDefinitions><ColumnDefinition Width="540"/><ColumnDefinition Width="20"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
   <ScrollViewer Grid.Column="0" VerticalScrollBarVisibility="Auto" Padding="0,0,8,0"><StackPanel>
    <GroupBox Header="① 选择材料"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="92"/></Grid.ColumnDefinitions>
     <StackPanel><Label Content="CIF / POSCAR 文件，或程序内置材料"/><TextBox x:Name="MaterialBox" Height="38"/></StackPanel>
     <Button x:Name="BrowseMaterial" Grid.Column="1" Content="浏览…" VerticalAlignment="Bottom" Height="38" Margin="10,0,0,0"/>
    </Grid></GroupBox>
    <GroupBox Header="② 添加溶剂 / 离子"><StackPanel>
     <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="110"/><ColumnDefinition Width="110"/></Grid.ColumnDefinitions>
      <StackPanel><Label Content="选择一个或多个 PDB 文件，加载后直接设置数量或比例"/><TextBlock Text="支持内置模板，也支持电脑上的任意 PDB 文件" Foreground="#7B879A" FontSize="12" Margin="0,4,0,0"/></StackPanel>
      <Button x:Name="AddSolventButton" Grid.Column="1" Content="添加 PDB…" Height="38" Margin="10,0,0,0"/>
      <Button x:Name="RemoveSolventButton" Grid.Column="2" Content="移除选中" Height="38" Margin="10,0,0,0"/>
     </Grid>
     <Grid Margin="0,12,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="170"/></Grid.ColumnDefinitions>
      <DataGrid x:Name="SolventGrid" AutoGenerateColumns="False" CanUserAddRows="False" CanUserDeleteRows="False" HeadersVisibility="Column" Height="150" SelectionMode="Single" BorderBrush="#D7DEEA" Background="White" FontSize="13">
       <DataGrid.Columns><DataGridTextColumn Header="PDB 文件" Binding="{Binding Name}" IsReadOnly="True" Width="*"/><DataGridTextColumn Header="数量 / 比例" Binding="{Binding Value, UpdateSourceTrigger=PropertyChanged}" Width="110"/></DataGrid.Columns>
      </DataGrid>
      <StackPanel Grid.Column="1" Margin="14,0,0,0"><Label Content="配比填写方式"/><ComboBox x:Name="CompositionMode" Height="38"><ComboBoxItem Content="比例" IsSelected="True"/><ComboBoxItem Content="数量"/></ComboBox><TextBlock Text="切换时自动换算：比例总和为 1，数量按总量 100 表示。" TextWrapping="Wrap" Foreground="#7B879A" FontSize="12" Margin="0,8,0,0"/></StackPanel>
     </Grid>
    </StackPanel></GroupBox>
    <GroupBox Header="③ 溶液密度与表面距离"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="1.05*"/><ColumnDefinition Width="1.2*"/><ColumnDefinition Width="1.2*"/></Grid.ColumnDefinitions>
     <StackPanel Margin="0,0,12,0"><Label Content="质量密度（g/cm³）"/><TextBox x:Name="DensityBox" Text="1.0" Height="38"/></StackPanel>
     <StackPanel Grid.Column="1" Margin="0,0,12,0"><Label Content="材料原子中心–溶剂原子中心最近距离（Å）"/><TextBox x:Name="SurfaceDistanceBox" Text="3.0" Height="38"/><TextBlock Text="会参与自由体积计算；基准默认 3.0 Å" Foreground="#7B879A" FontSize="11" Margin="0,4,0,0"/></StackPanel>
     <StackPanel Grid.Column="2"><Label Content="原子中心距离填充范围（Å）"/><TextBox x:Name="SurfaceRangeBox" Text="0" Height="38"/><TextBlock Text="0 = 整个可用自由空间，也会参与计算" Foreground="#7B879A" FontSize="11" Margin="0,4,0,0"/></StackPanel>
    </Grid></GroupBox>
    <GroupBox Header="④ 计算设置"><Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
     <Grid Grid.Row="0" Margin="0,0,0,12"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="130"/><ColumnDefinition Width="130"/><ColumnDefinition Width="130"/></Grid.ColumnDefinitions>
      <StackPanel Margin="0,0,12,0"><Label Content="输出文件"/><TextBox x:Name="OutputBox" Text="filled.gro" Height="38"/></StackPanel>
      <StackPanel Grid.Column="1" Margin="0,0,12,0"><Label Content="输出格式"/><ComboBox x:Name="OutputFormat" Height="38"><ComboBoxItem Content="GRO" IsSelected="True"/><ComboBoxItem Content="CIF"/></ComboBox></StackPanel>
      <StackPanel Grid.Column="2" Margin="0,0,12,0" Visibility="Collapsed"><Label Content="速度档位"/><ComboBox x:Name="SpeedCombo" Height="38"/></StackPanel>
      <StackPanel Grid.Column="3" Margin="0,0,12,0" Visibility="Collapsed"><Label Content="填充模式"/><ComboBox x:Name="FillCombo" Height="38"/></StackPanel>
      <StackPanel Visibility="Collapsed"><Label Content="空间类型"/><ComboBox x:Name="ModeCombo" Height="38"/></StackPanel>
     </Grid>
     <Grid Grid.Row="1" Margin="0,0,0,12"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <StackPanel Grid.ColumnSpan="3" Width="220" HorizontalAlignment="Left" Margin="0,0,12,0"><Label Content="周期方向"/><ComboBox x:Name="PeriodicCombo" Height="38"/></StackPanel>
      <StackPanel Grid.Column="1" Margin="0,0,12,0" Visibility="Collapsed"><Label Content="表面侧向"/><ComboBox x:Name="SideCombo" Height="38"/></StackPanel>
      <StackPanel Grid.Column="2" Visibility="Collapsed"><Label Content="随机种子"/><TextBox x:Name="SeedBox" Text="20260826" Height="38"/></StackPanel>
     </Grid>
     <Expander Grid.Row="2" x:Name="AdvancedExpander" Header="高级参数（一般不需要修改）" FontSize="13" Foreground="#516079" Visibility="Collapsed"><Grid Margin="0,12,0,0">
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0" Margin="0,0,12,0"><Label Content="安全距离 Å"/><TextBox x:Name="ToleranceBox" Text="1.5" Height="34"/></StackPanel>
      <StackPanel Grid.Column="1" Margin="0,0,12,0"><Label Content="自由体积网格 Å"/><TextBox x:Name="GridBox" Text="1.5" Height="34"/></StackPanel>
      <StackPanel Grid.Column="2"><Label Content="离子最小空间 Å"/><TextBox x:Name="IonSpaceBox" Text="4.0" Height="34"/></StackPanel>
      <StackPanel Grid.Column="0" Margin="0,78,12,0"><Label Content="Z 最小值（可空）"/><TextBox x:Name="ZMinBox" Height="34"/></StackPanel>
      <StackPanel Grid.Column="1" Margin="0,78,12,0"><Label Content="Z 最大值（可空）"/><TextBox x:Name="ZMaxBox" Height="34"/></StackPanel>
     </Grid></Expander>
    </Grid></GroupBox>
   </StackPanel></ScrollViewer>
   <Grid Grid.Column="2"><Grid.RowDefinitions><RowDefinition Height="170"/><RowDefinition Height="*"/><RowDefinition Height="220"/></Grid.RowDefinitions>
    <GroupBox Grid.Row="0" Header="快速开始"><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
     <Button x:Name="CaseA" Style="{StaticResource SoftButton}" Height="76" HorizontalContentAlignment="Left" Padding="15,10"><StackPanel><TextBlock Text="沟壑表面 · ZnSO₄ 水溶液" FontWeight="SemiBold" Foreground="#1D4ED8"/><TextBlock Text="载入示例参数" Margin="0,6,0,0" Foreground="#5B6E8F" FontSize="12"/></StackPanel></Button>
     <Button x:Name="CaseB" Grid.Column="1" Style="{StaticResource SoftButton}" Height="76" HorizontalContentAlignment="Left" Padding="15,10" Margin="8,0,0,0"><StackPanel><TextBlock Text="IRMOF-10 · LiPF₆ 电解液" FontWeight="SemiBold" Foreground="#1D4ED8"/><TextBlock Text="载入示例参数" Margin="0,6,0,0" Foreground="#5B6E8F" FontSize="12"/></StackPanel></Button>
    </Grid></GroupBox>
    <GroupBox Grid.Row="1" Header="运行前检查 / 命令预览"><Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
     <Border Grid.Row="0" Background="#FFF8E8" BorderBrush="#F3D48A" BorderThickness="1" CornerRadius="8" Padding="12,9" Margin="0,0,0,12"><TextBlock x:Name="HintText" TextWrapping="Wrap" Foreground="#8A5A00"/></Border>
     <TextBox Grid.Row="1" x:Name="PreviewBox" IsReadOnly="True" TextWrapping="Wrap" AcceptsReturn="True" VerticalScrollBarVisibility="Auto" Background="#F8FAFD" BorderBrush="#E3E9F2" FontFamily="Consolas" FontSize="13" Padding="13"/>
     <Grid Grid.Row="2" Margin="0,12,0,0"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
      <StackPanel Orientation="Horizontal" VerticalAlignment="Center"><Ellipse x:Name="StatusDot" Width="9" Height="9" Fill="#A6B2C5" Margin="0,0,8,0"/><TextBlock x:Name="StatusText" Text="待机" Foreground="#68758B" VerticalAlignment="Center"/></StackPanel>
      <Button x:Name="RunButton" Grid.Column="1" Content="开始生成" Style="{StaticResource PrimaryButton}" Height="42"/><Button x:Name="StopButton" Grid.Column="1" Content="停止" Height="42" Visibility="Collapsed"/>
     </Grid>
    </Grid></GroupBox>
    <GroupBox Grid.Row="2" Header="运行日志"><TextBox x:Name="LogBox" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto" Background="White" BorderBrush="Transparent" FontFamily="Consolas" FontSize="12" Padding="0"/></GroupBox>
   </Grid>
  </Grid>
  <Border Grid.Row="2" Background="White" BorderBrush="#E2E7F0" BorderThickness="0,1,0,0" Padding="24,0"><Grid>
   <TextBlock Text="底层引擎：solvforge.exe  ·  可输出 GRO / CIF 结构文件  ·  开发者微信：x1aohua501" Foreground="#8490A3" VerticalAlignment="Center" FontSize="12"/>
   <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center"><Button x:Name="OpenFolderButton" Content="打开程序目录" Height="32" Padding="12,5"/><Button x:Name="OpenOutputButton" Content="打开输出位置" Height="32" Padding="12,5" IsEnabled="False"/></StackPanel>
  </Grid></Border>
 </Grid>
</Window>
'@

$reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)
function C([string]$name) { $window.FindName($name) }

$material=C 'MaterialBox'; $solventGrid=C 'SolventGrid'; $compositionMode=C 'CompositionMode'; $addSolvent=C 'AddSolventButton'; $removeSolvent=C 'RemoveSolventButton'
$density=C 'DensityBox'; $surfaceDistance=C 'SurfaceDistanceBox'; $surfaceRange=C 'SurfaceRangeBox'; $output=C 'OutputBox'; $outputFormat=C 'OutputFormat'; $speed=C 'SpeedCombo'; $fill=C 'FillCombo'; $mode=C 'ModeCombo'; $periodic=C 'PeriodicCombo'; $side=C 'SideCombo'; $seed=C 'SeedBox'; $tolerance=C 'ToleranceBox'; $grid=C 'GridBox'; $ionSpace=C 'IonSpaceBox'; $zMin=C 'ZMinBox'; $zMax=C 'ZMaxBox'; $preview=C 'PreviewBox'; $hint=C 'HintText'; $run=C 'RunButton'; $stop=C 'StopButton'; $status=C 'StatusText'; $statusDot=C 'StatusDot'; $logBox=C 'LogBox'; $openOutput=C 'OpenOutputButton'; $openFolder=C 'OpenFolderButton'
$caseA=C 'CaseA'; $caseB=C 'CaseB'; $browseMaterial=C 'BrowseMaterial'

$script:solvents = New-Object System.Collections.ObjectModel.ObservableCollection[object]
$solventGrid.ItemsSource = $script:solvents
$script:solutionPreviewPath = Join-Path $env:TEMP 'solvforge_gui_solution.tsv'
$script:lastCompositionMode = '比例'

function Add-Items($control,[string[]]$items,[string]$selected) { foreach($item in $items){[void]$control.Items.Add($item)}; if($selected){$control.SelectedItem=$selected} }
Add-Items $speed @('快速（推荐）','平衡','精细') '快速（推荐）'
Add-Items $fill @('adaptive','standard','complete') 'complete'; Add-Items $mode @('自动','surface','pore','accessible','ion') '自动'; Add-Items $periodic @('xy','xyz','x','y','z') 'xy'; Add-Items $side @('both','above','below') 'both'

function RelPath([string]$path) { if([string]::IsNullOrWhiteSpace($path)){return ''}; if([IO.Path]::IsPathRooted($path)){return $path}; return (Join-Path $baseDir $path) }
function Arg([string]$value) { return '"' + (($value -replace '"','\"')) + '"' }
function OutputFormatText {
 $item=$outputFormat.SelectedItem
 if($item -is [Windows.Controls.ComboBoxItem]){return [string]$item.Content}
 if([string]::IsNullOrWhiteSpace([string]$item)){return 'GRO'}
 return [string]$item
}
function OutputPathText {
 $name=$output.Text.Trim();if(!$name){return ''}
 $ext='.gro';if((OutputFormatText) -eq 'CIF'){$ext='.cif'}
 return [IO.Path]::ChangeExtension($name,$ext)
}
function Sync-OutputFormat {
 $name=$output.Text.Trim();if(!$name){return}
 $ext='.gro';if((OutputFormatText) -eq 'CIF'){$ext='.cif'}
 $output.Text=[IO.Path]::ChangeExtension($name,$ext)
}
function Set-OutputFormatFromPath {
 $ext=[IO.Path]::GetExtension($output.Text)
 if($ext -and $ext.Equals('.cif',[StringComparison]::OrdinalIgnoreCase)){$outputFormat.SelectedIndex=1}else{$outputFormat.SelectedIndex=0}
}
function SelectedRows { return @($script:solvents | Where-Object { $_.Path -and (Test-Path -LiteralPath $_.Path) }) }
function RowValue($row) { $v=0.0; if([double]::TryParse([string]$row.Value,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$v) -and $v -gt 0){return $v}; return 0.0 }
function CompositionModeText {
 $item=$compositionMode.SelectedItem
 if($item -is [Windows.Controls.ComboBoxItem]){return [string]$item.Content}
 return [string]$item
}
function Convert-CompositionValues {
 $newMode=CompositionModeText
 $rows=@($script:solvents);$total=0.0
 foreach($row in $rows){$total+=RowValue $row}
 if($newMode -eq $script:lastCompositionMode -and !($newMode -eq '比例' -and $total -gt 1.0000001)){return}
 if($total -gt 0){
  if($newMode -eq '比例'){
   foreach($row in $rows){$v=RowValue $row;$row.Value=($v/$total).ToString('0.########',[Globalization.CultureInfo]::InvariantCulture)}
  } elseif($newMode -eq '数量'){
   $floors=New-Object System.Collections.Generic.List[int];$remainders=New-Object System.Collections.Generic.List[double];$assigned=0
   foreach($row in $rows){$exact=(RowValue $row)/$total*100.0;$base=[int][Math]::Floor($exact);[void]$floors.Add($base);[void]$remainders.Add($exact-$base);$assigned+=$base}
   while($assigned -lt 100){$best=0;for($i=1;$i -lt $remainders.Count;$i++){if($remainders[$i] -gt $remainders[$best]){$best=$i}};$floors[$best]++;$remainders[$best]=-1.0;$assigned++}
   for($i=0;$i -lt $rows.Count;$i++){$rows[$i].Value=$floors[$i].ToString('0',[Globalization.CultureInfo]::InvariantCulture)}
  }
  $solventGrid.Items.Refresh()
 }
 $script:lastCompositionMode=$newMode
}
function Prepare-SolutionFile {
 $rows=SelectedRows;if($rows.Count -lt 2){return ''};$total=0.0;foreach($row in $rows){$total+=RowValue $row};if($total -le 0){throw '请为每个 PDB 填写大于 0 的数量或比例。'}
 $inputDir=Join-Path $baseDir '.solvforge_gui_inputs';if(!(Test-Path -LiteralPath $inputDir)){New-Item -ItemType Directory -Path $inputDir -Force|Out-Null};$lines=New-Object System.Collections.Generic.List[string];$i=0;foreach($row in $rows){$i++;$safe='pdb_'+$i+'.pdb';$dest=Join-Path $inputDir $safe;Copy-Item -LiteralPath (RelPath $row.Path) -Destination $dest -Force;$v=(RowValue $row)/$total;[void]$lines.Add($dest+' '+$v.ToString('0.########', [Globalization.CultureInfo]::InvariantCulture))};[IO.File]::WriteAllLines($script:solutionPreviewPath,$lines,[Text.UTF8Encoding]::new($false));return $script:solutionPreviewPath
}
function CommandText {
 $a=New-Object System.Collections.Generic.List[string]; [void]$a.Add('--material');[void]$a.Add((RelPath $material.Text));$rows=SelectedRows;
 if($rows.Count -eq 1){[void]$a.Add('--solvent');[void]$a.Add([string]$rows[0].Path)}else{[void]$a.Add('--solution');[void]$a.Add($script:solutionPreviewPath)}
 [void]$a.Add('--density');[void]$a.Add($density.Text)
 [void]$a.Add('--fill');[void]$a.Add('complete'); if($mode.SelectedItem -ne '自动'){[void]$a.Add('--mode');[void]$a.Add([string]$mode.SelectedItem)}
 [void]$a.Add('--periodic');[void]$a.Add([string]$periodic.SelectedItem);[void]$a.Add('--side');[void]$a.Add('both');[void]$a.Add('--material-solvent-min-distance');[void]$a.Add($surfaceDistance.Text);[void]$a.Add('--surface-fill-range');[void]$a.Add($surfaceRange.Text);[void]$a.Add('--tolerance');[void]$a.Add('1.5');[void]$a.Add('--grid');[void]$a.Add('1.5');[void]$a.Add('--ion-min-free-space');[void]$a.Add('4.0')
 [void]$a.Add('--seed');[void]$a.Add('20260826');[void]$a.Add('--output');[void]$a.Add((RelPath (OutputPathText)));[void]$a.Add('--no-wait'); return (($a|ForEach-Object{Arg $_}) -join ' ')
}
function Set-Status([string]$text,[string]$color){$status.Text=$text;$statusDot.Fill=(New-Object Windows.Media.BrushConverter).ConvertFromString($color)}
function Update-Preview { $preview.Text="solvforge.exe`n  "+(CommandText);$missing=@();if(!$material.Text.Trim()){$missing+='材料文件'};if((SelectedRows).Count -eq 0){$missing+='至少一个 PDB 文件'};if(!$output.Text.Trim()){$missing+='输出文件'};if($missing.Count){$hint.Text='还需要填写：'+($missing -join '、')+'。也可以先点击上面的快速案例。';$hint.Foreground=(New-Object Windows.Media.BrushConverter).ConvertFromString('#8A5A00')}else{$hint.Text='参数已基本就绪。多种 PDB 的配比由界面后台自动生成，无需准备 TSV 文件。';$hint.Foreground=(New-Object Windows.Media.BrushConverter).ConvertFromString('#176B51')}}
function Update-State { $density.IsEnabled=$true;Update-Preview }
function Add-Rows([string[]]$paths,[string[]]$values){for($i=0;$i -lt $paths.Count;$i++){if(Test-Path -LiteralPath $paths[$i]){if(-not ($script:solvents|Where-Object{$_.Path -eq $paths[$i]})){[void]$script:solvents.Add([PSCustomObject]@{Name=[IO.Path]::GetFileName($paths[$i]);Path=$paths[$i];Value=if($values -and $i -lt $values.Count){$values[$i]}else{'1.0'}})}}};$solventGrid.Items.Refresh();Update-Preview}
function Set-Preset([string]$m,[string[]]$pdb,[string[]]$values,[string]$out,[string]$modeValue,[string]$periodicValue){$material.Text=$m;$script:solvents.Clear();Add-Rows $pdb $values;$output.Text=$out;Set-OutputFormatFromPath;$mode.SelectedItem=$modeValue;$periodic.SelectedItem=$periodicValue;$speed.SelectedItem='快速（推荐）';$fill.SelectedItem='complete';$script:lastCompositionMode='数量';Convert-CompositionValues;Update-State;Set-Status '已载入示例参数' '#2563EB'}

$browseMaterial.Add_Click({$d=New-Object Microsoft.Win32.OpenFileDialog;$d.Filter='结构文件 (*.cif;*.vasp;POSCAR)|*.cif;*.vasp;POSCAR|所有文件 (*.*)|*.*';if($d.ShowDialog()){$material.Text=$d.FileName;Update-Preview}})
$addSolvent.Add_Click({$d=New-Object Microsoft.Win32.OpenFileDialog;$d.Filter='PDB 分子模板 (*.pdb)|*.pdb|所有文件 (*.*)|*.*';$d.Multiselect=$true;if($d.ShowDialog()){Add-Rows $d.FileNames $null}})
$removeSolvent.Add_Click({if($solventGrid.SelectedItem){$script:solvents.Remove($solventGrid.SelectedItem);$solventGrid.Items.Refresh();Update-Preview}})
$openFolder.Add_Click({Start-Process explorer.exe -ArgumentList (Arg $baseDir)})
$openOutput.Add_Click({$f=RelPath (OutputPathText);if(Test-Path -LiteralPath $f){Start-Process explorer.exe -ArgumentList '/select,', (Arg $f)}elseif(Test-Path -LiteralPath (Split-Path -Parent $f)){Start-Process explorer.exe -ArgumentList (Arg (Split-Path -Parent $f))}})
$compositionMode.Add_SelectionChanged({Convert-CompositionValues;Update-Preview})
foreach($control in @($material,$density,$surfaceDistance,$surfaceRange,$output)){$control.Add_TextChanged({Update-Preview})};foreach($control in @($mode,$periodic)){$control.Add_SelectionChanged({Update-Preview})};$outputFormat.Add_SelectionChanged({Sync-OutputFormat;Update-Preview});$solventGrid.Add_CellEditEnding({Update-Preview})
$caseA.Add_Click({Set-Preset 'examples\rugged_slab_demo.cif' @('templates\solvents\water_tip3p.pdb','templates\solvents\Zn.pdb','templates\solvents\SO4.pdb') @('55','1','1') 'rugged_slab_ZnSO4_1M.gro' 'surface' 'xy'})
$caseB.Add_Click({Set-Preset 'templates\materials\raspa2\mofs\cif\IRMOF-10.cif' @('templates\solvents\ethylene_carbonate.pdb','templates\solvents\dimethyl_carbonate.pdb','templates\solvents\Li.pdb','templates\solvents\PF6.pdb') @('54','54','2','2') 'IRMOF-10_LiPF6_1M.gro' 'pore' 'xyz'})

function Set-CompletionHint($j) {
 if((OutputFormatText) -eq 'GRO') {
  $hint.Text="本次已完成，窗口仍保持打开：主文件 GRO；同时生成 CIF 检查副本；放置 $($j.placed_molecules) 个分子/离子；候选空间 $($j.candidate_points) 点。修改参数后可直接再次生成。"
 } else {
  $hint.Text="本次已完成，窗口仍保持打开：主文件 CIF；放置 $($j.placed_molecules) 个分子/离子；候选空间 $($j.candidate_points) 点。修改参数后可直接再次生成。"
 }
 $hint.Foreground=(New-Object Windows.Media.BrushConverter).ConvertFromString('#176B51')
}

$timer=New-Object System.Windows.Threading.DispatcherTimer;$timer.Interval=[TimeSpan]::FromMilliseconds(350);$timer.Add_Tick({if($null -eq $script:process){return};foreach($pair in @(@($script:stdoutPath,[ref]$script:stdoutLength),@($script:stderrPath,[ref]$script:stderrLength))){$p=$pair[0];$ref=$pair[1];if(Test-Path -LiteralPath $p){$txt=[IO.File]::ReadAllText($p);if($txt.Length -gt $ref.Value){$logBox.AppendText($txt.Substring($ref.Value));$ref.Value=$txt.Length;$logBox.ScrollToEnd()}}};if($script:process.HasExited){$timer.Stop();$code=$script:process.ExitCode;$script:process.Dispose();$script:process=$null;$run.Visibility='Visible';$stop.Visibility='Collapsed';if($code -eq 0){Set-Status '生成完成，窗口仍保持打开' '#159570';$openOutput.IsEnabled=$true;$report=(RelPath (OutputPathText))+'.report.json';if(Test-Path -LiteralPath $report){try{$j=Get-Content -LiteralPath $report -Raw|ConvertFrom-Json;Set-CompletionHint $j}catch{$hint.Text='生成完成，窗口仍保持打开，已输出所选格式的结构文件和报告文件。'}}}else{Set-Status "运行失败（退出码 $code）" '#C53030';$hint.Text='运行未成功，请查看下方日志。常见原因是材料路径、模板名或目标数量不合适。';$hint.Foreground=(New-Object Windows.Media.BrushConverter).ConvertFromString('#A12A2A')}}})
$run.Add_Click({
 if(!(Test-Path -LiteralPath $exePath)){[Windows.MessageBox]::Show('找不到 solvforge.exe，请确认程序目录完整。','SolvForge');return}
 if(!$material.Text.Trim()){[Windows.MessageBox]::Show('请先选择材料 CIF / POSCAR 文件。','还缺少材料');return}
 if(!(Test-Path -LiteralPath (RelPath $material.Text))){[Windows.MessageBox]::Show('找不到材料文件：'+$material.Text,'材料文件不存在');return}
 $rows=SelectedRows;if($rows.Count -eq 0){[Windows.MessageBox]::Show('请先添加至少一个 PDB 分子模板。','还缺少 PDB');return}
 if(!(OutputPathText).Trim()){[Windows.MessageBox]::Show('请填写输出文件名。','还缺少输出文件');return}
 try{if($rows.Count -gt 1){[void](Prepare-SolutionFile)}}catch{[Windows.MessageBox]::Show($_.Exception.Message,'PDB 数量/比例不正确');return}
 $outPath=RelPath (OutputPathText);$outDir=Split-Path -Parent $outPath;if(!(Test-Path -LiteralPath $outDir)){New-Item -ItemType Directory -Path $outDir -Force|Out-Null}
 $stamp=[DateTime]::Now.ToString('yyyyMMdd_HHmmss_fff');$script:stdoutPath=Join-Path $env:TEMP "solvforge_gui_$stamp.out.log";$script:stderrPath=Join-Path $env:TEMP "solvforge_gui_$stamp.err.log";[IO.File]::WriteAllText($script:stdoutPath,'');[IO.File]::WriteAllText($script:stderrPath,'');$script:stdoutLength=0;$script:stderrLength=0;$logBox.Clear();$logBox.AppendText("开始运行…`r`n"+(CommandText)+"`r`n`r`n")
 $psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName=$exePath;$psi.WorkingDirectory=$baseDir;$psi.Arguments=CommandText;$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$script:process=New-Object Diagnostics.Process;$script:process.StartInfo=$psi;$script:process.add_OutputDataReceived({param($s,$e)if($e.Data){[IO.File]::AppendAllText($script:stdoutPath,$e.Data+[Environment]::NewLine)}});$script:process.add_ErrorDataReceived({param($s,$e)if($e.Data){[IO.File]::AppendAllText($script:stderrPath,$e.Data+[Environment]::NewLine)}})
 try{[void]$script:process.Start();$script:process.BeginOutputReadLine();$script:process.BeginErrorReadLine();$run.Visibility='Collapsed';$stop.Visibility='Visible';$openOutput.IsEnabled=$false;Set-Status '正在生成…' '#2563EB';$timer.Start()}catch{Set-Status '启动失败' '#C53030';$run.Visibility='Visible';$stop.Visibility='Collapsed';[Windows.MessageBox]::Show($_.Exception.Message,'无法启动 SolvForge')}
})
$stop.Add_Click({if($null -ne $script:process -and !$script:process.HasExited){$script:process.Kill();Set-Status '已停止' '#C53030';$logBox.AppendText("`r`n已由用户停止。`r`n")}})
$window.Add_Closing({if($null -ne $script:process -and !$script:process.HasExited){$ans=[Windows.MessageBox]::Show('任务仍在运行，确定要停止并退出吗？','确认退出',[Windows.MessageBoxButton]::YesNo,[Windows.MessageBoxImage]::Warning);if($ans -eq [Windows.MessageBoxResult]::No){$_.Cancel=$true}else{$script:process.Kill()}}})
Update-State;Update-Preview;[void]$window.ShowDialog()
