Table of Contents
=================

   * [A MATLAB importer for Mastodon files.](#a-matlab-importer-for-mastodon-files)
      * [Running a quick demo.](#running-a-quick-demo)
      * [Installation.](#installation)
      * [Usage.](#usage)
         * [The data graph.](#the-data-graph)
         * [The ellipsoid and the covariance matrix.](#the-ellipsoid-and-the-covariance-matrix)
         * [The metadata.](#the-metadata)
         * [The tag-set structure.](#the-tag-set-structure)
      * [Performance.](#performance)
      * [Limitation.](#limitation)
      * [Examples.](#examples)
         * [Import the full track graph and the spot ellipsoids.](#import-the-full-track-graph-and-the-spot-ellipsoids)
            * [Import the tags and use them to color spots and links.](#import-the-tags-and-use-them-to-color-spots-and-links)
         * [The MaMuT dataset imported as ellipsoids.](#the-mamut-dataset-imported-as-ellipsoids)
         * [Colouring individual tracks.](#colouring-individual-tracks)
         * [A smaller dataset.](#a-smaller-dataset)
         * [Inspecting the data numerical features.](#inspecting-the-data-numerical-features)





# A MATLAB importer for Mastodon files.

This repository contains several MATLAB functions used to import Mastodon files (https://github.com/fiji/TrackMate3). The import procedure is based on directly deserialising the binary files using MATLAB low-level API, and therefore has no dependency. 



## Running a quick demo.

Run the demo script `demo_import_and_plot.m` in the `demo/` folder.

## Installation.

Simply add all the files of the `src/` folder to your MATLAB path.

## Usage.

The main function is `import_mastodon( path/to/your/mastodon/file.mastodon )`.

```matlab
[ G, metadata, tss ] = import_mastodon( source_file );
```

### The data graph.

The data is returned as a MATLAB directed graph already:

```matlab
>> G

G = 

  digraph with properties:

    Edges: [2981×6 table]
    Nodes: [3087×22 table]
```

The spots are listed in the `Nodes` table of the graph. The links are listed in the `Edges` table. 



Everything is imported: the model, the numerical features and the tags:

```matlab
>> head(G.Nodes)

ans =

  8×22 table

    id      x         y         z       t     c_11       c_12      c_13     c_22     c_23
    __    ______    ______    ______    _    ______    ________    ____    ______    ____

    0     61.362    76.349    55.142    0    22.502     0.91281     0      21.628     0  
    1     113.15    3.2331     67.34    0    35.087      6.6417     0      20.584     0  
    2     35.741    20.075     57.84    0      24.6     -6.5254     0      28.333     0  
    3     79.251    35.248    56.869    0    19.096     0.19479     0      34.124     0  
    4     143.31    95.934    77.957    0    31.404     -1.9327     0      18.281     0  
    5     114.93    97.665    65.717    0    25.358    -0.42869     0      18.027     0  
    6     129.54    98.146    70.754    0    23.942    -0.66575     0      18.076     0  
    7      36.41    50.149    57.431    0    26.004      7.9379     0      25.876     0  
...
 
  c_33      bsrs     label      Fruits          Names       SpotNLinks    SpotTrackID 
 ______    ______    _____    ___________    ___________    __________    ___________ 

 181.48    725.93     '0'     Apple          Mike               1               0     
 82.768    331.07     '1'     Apple          <undefined>        1             105     
 146.87    587.46     ''      Banana         Robert             1             104     
  170.8    683.21     ''      Kiwi           Myriam             1             103     
 122.11    488.43     ''      Kiwi           Assaf              1             102     
 115.41    461.63     ''      <undefined>    <undefined>        1             101     
 86.567    346.27     ''      <undefined>    <undefined>        1             100     
    158    631.99     ''      <undefined>    <undefined>        1              99     

...

```



The `id` column corresponds to the Mastodon internal object id. However, the link table follows MATLAB convention. It has a variable called `EndNodes` made of two columns containing the source and target spots of each link. But the `EndNodes` values refer to **row indices in the spots table**, not to the spot ids. 

```matlab
>> head(G.Edges)

ans =

  8×6 table

    EndNodes    id      Fruits          Names       LinkDisplacement    LinkVelocity
    ________    __    ___________    ___________    ________________    ____________

    1     95    0     <undefined>    Chris               1.3555            1.3555   
    2     96    1     Apple          Roy                0.41863           0.41863   
    3     97    2     Banana         <undefined>        0.65284           0.65284   
    4     98    3     Kiwi           <undefined>        0.95254           0.95254   
    5     99    4     <undefined>    <undefined>        0.52254           0.52254   
    6    100    5     <undefined>    <undefined>        0.77146           0.77146   
    7    101    6     <undefined>    <undefined>        0.83214           0.83214   
    8    102    7     <undefined>    Joe                0.71399           0.71399   
```



The tables store also the physical units of the variables they store:

```matlab
>> head(G.Edges, 1)

ans =

  1×6 table

    EndNodes    id      Fruits       Names    LinkDisplacement    LinkVelocity
    ________    __    ___________    _____    ________________    ____________

    1    95     0     <undefined>    Chris         1.3555            1.3555   

>> G.Edges.Properties.VariableUnits

ans =

  1×6 cell array

    {0×0 char}    {0×0 char}    {0×0 char}    {0×0 char}    {'um'}    {'um/frame'}
```

And their description when available:

```matlab
>> G.Edges.Properties.VariableDescriptions'

ans =

  6×1 cell array

    {0×0 char}
    {0×0 char}
    {0×0 char}
    {0×0 char}
    {'Computes the link displacement in physical units as the distance between the source spot and the target spot.'                                              }
    {'Computes the link velocity as the distance between the source and target spots divided by their frame difference. Units are in physical distance per frame.'}

```

### The ellipsoid and the covariance matrix.

The spot ellipsoid shape is represented through a covariance matrix. The covariance matrix itself is stored in the variables `c_11`, `c_12`, `c_13`, `c_22`, `c_23`, `c_33`, so that this symmetric real 3x3 matrix can be expressed as:

``` matlab
C = 	[  	c_11, 	c_12, 	c_13
		c_12, 	c_22,	c_23
		c_13,	c_23,	c_33 ];
```

The `bsrs`  variable contains the bounding-sphere radius squared. It is the radius of the smallest sphere that includes the spot ellipsoid fully, squared.

In the `demo_import_and_plot.m` file there is a function can plot the spot ellipsoid. You would use it for instance like this:

```matlab
spots = G.Nodes;
i = 1;
spot = spots( i, : );

M = [ spot.x; spot.y; spot.z ];
C = [
  spot.c_11, spot.c_12, spot.c_13
  spot.c_12, spot.c_22, spot.c_23
  spot.c_13, spot.c_23, spot.c_33
];

h(i) = plot_ellipsoid( M, C );
set( h(i), ...
  'EdgeColor', 'None', ...
  'FaceColor', 'b', ...
  'FaceLighting', 'Flat' );
light()
```

### The metadata.

We also retrieve the metadata, made mainly of the physical units, and the absolute path to the XML/H5 BDV file:

```matlab
>> metadata

metadata = 

  struct with fields:

                     version: '0.3'
         spim_data_file_path: '/Users/tinevez/Development/Mastodon/TrackMate3/samples/mamutproject/datasethdf5.xml'
    spim_data_file_path_type: 'absolute'
                 space_units: 'um'
                  time_units: 'frame'
```

### The tag-set structure.

The last variable returned is the tag-set structure. For each tag-set, it contains its label, its id and the tag list.

```matlab
>> tss

tss = 

  2×1 struct array with fields:

    id
    name
    tags

>> tss(1)

ans = 

  struct with fields:

      id: 0
    name: 'Fruits'
    tags: [3×1 struct]
```

The tags themselves are a `struct` with an id, a label and a color encoded as an integer.

```matlab
>> tss(1).tags(1)

ans = 

  struct with fields:

    label: 'Apple'
       id: 0
    color: -52480
```

In the `demo_import_and_plot.m` file there is a function to convert the `int` color into a RGB triplet. I might as well give it here:

```matlab
function rgb = to_hex_color( val )
    hex_code = dec2hex( typecast( int32( val ), 'uint32'  ) );   
    rgb = reshape( sscanf( hex_code( 1 : 6 ).', '%2x' ), 3, []).' / 255;    
end

>> val = tss(1).tags(1).color;
>> rgb = to_hex_color( val )l
>> rgb

rgb =

    1.0000    1.0000    0.2000
```



## Performance.

On my MacPro I tested the import of a dataset made of about  30k objects (spots and links) in less than 1s. 

## Limitation.

The importer strongly depends on how the Mastodon file format is written. Any changes made to the serialisation procedure in the Java Mastodon project will likely break the importer. Right now the importer echoes a warning if the Mastodon file version is not 0.3.

## Examples.

The screenshots below mostly exemplify what can be done from the imported data structure, with the MATLAB visualisation tools.

### Import the full track graph and the spot ellipsoids.

![After importing top view](images/ScreenShot1.png?raw=true "After importing top view")

![After importing side view](images/ScreenShot2.png?raw=true "After importing side view")


#### Import the tags and use them to color spots and links.

![Nodes table with tags](images/ScreenShot3.png?raw=true "Nodes table with tags")

![Coloring by tags](images/ScreenShot4.png?raw=true "Coloring by tags")

### The MaMuT dataset imported as ellipsoids.

This is the results of the detection of cells using the TGMM framework of Amat *et al.*, 2014.

![The MaMuT dataset](images/ScreenShot5.png?raw=true "The MaMuT dataset")

![The MaMuT dataset](images/ScreenShot6.png?raw=true "The MaMuT dataset")

### Colouring individual tracks.

![Tracks in the MaMuT dataset](images/ScreenShot7.png?raw=true "Tracks in the MaMuT dataset")

### A smaller dataset.

![A smaller dataset](images/ScreenShot9.png?raw=true "A smaller dataset")

![A smaller dataset](images/ScreenShot8.png?raw=true "A smaller dataset")

### Inspecting the data numerical features.

```matlab
figure;
s = scatter( G.Nodes.SpotGaussianFilteredIntensityMeanCh1, G.Nodes.z, 75, sqrt(G.Nodes.bsrs), 'filled' );
s.MarkerEdgeColor = [ 0.3 0.3 0.3 ];

xlabel( 'Mean intensity' );
ylabel( sprintf( 'Z position (%s)', G.Nodes.Properties.VariableUnits{4} ) )
colormap jet
c = colorbar;
c.Label.String = sprintf( 'Approx size (%s)', G.Nodes.Properties.VariableUnits{4} );
```

![Numerical features](images/ScreenShot10.png?raw=true "Numerical features")
