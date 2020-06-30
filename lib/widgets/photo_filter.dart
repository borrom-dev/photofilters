import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photofilters/filters/filters.dart';
import 'package:image/image.dart' as imageLib;
import 'package:path_provider/path_provider.dart';

import 'container_rectangle.dart';

class PhotoFilter extends StatelessWidget {
  final imageLib.Image image;
  final String filename;
  final Filter filter;
  final BoxFit fit;
  final Widget loader;

  PhotoFilter({
    @required this.image,
    @required this.filename,
    @required this.filter,
    this.fit = BoxFit.fill,
    this.loader = const Center(child: CircularProgressIndicator()),
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: compute(applyFilter, <String, dynamic>{
        "filter": filter,
        "image": image,
        "filename": filename,
      }),
      builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return loader;
          case ConnectionState.active:
          case ConnectionState.waiting:
            return loader;
          case ConnectionState.done:
            if (snapshot.hasError)
              return Center(child: Text('Error: ${snapshot.error}'));
            return Image.memory(
              snapshot.data,
              fit: fit,
            );
        }
        return null; // unreachable
      },
    );
  }
}

///The PhotoFilterSelector Widget for apply filter from a selected set of filters
class PhotoFilterSelector extends StatefulWidget {
  final Widget title;

  final List<Filter> filters;
  final imageLib.Image image;
  final Widget loader;
  final BoxFit fit;
  final String filename;
  final bool circleShape;

  const PhotoFilterSelector({
    Key key,
    @required this.title,
    @required this.filters,
    @required this.image,
    this.loader = const Center(child: CircularProgressIndicator()),
    this.fit = BoxFit.fill,
    @required this.filename,
    this.circleShape = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _PhotoFilterSelectorState();
}

class _PhotoFilterSelectorState extends State<PhotoFilterSelector> {
  String filename;
  Map<String, List<int>> cachedFilters = {};
  Filter _filter;
  imageLib.Image image;
  bool loading;

//  final List<Filter> filters;

  @override
  void initState() {
    super.initState();
    loading = false;
    _filter = widget.filters[0];
    filename = widget.filename;
    image = widget.image;
    calculateFilters();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void calculateFilters() async {
    for (int i = 0; i < widget.filters.length; i++) {
      var filter = await compute(
        applyFilter,
        <String, dynamic>{
          "filter": widget.filters[i],
          "image": image,
          "filename": filename
        },
      );
      cachedFilters[widget.filters[i]?.name ?? "_"] = filter;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: widget.title,
        actions: <Widget>[
          loading
              ? Container()
              : IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () async {
                    setState(() {
                      loading = true;
                    });
                    var imageFile = await saveFilteredImage();

                    Navigator.pop(context, {'image_filtered': imageFile});
                  },
                )
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: loading
            ? widget.loader
            : Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: EdgeInsets.all(12.0),
                      child: _buildFilteredImage(
                        _filter,
                        image,
                        filename,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.filters.length == cachedFilters.length
                            ? cachedFilters.length
                            : cachedFilters.length + 1,
                        itemBuilder: (BuildContext context, int index) {
                          return widget.filters.length !=
                                      cachedFilters.length &&
                                  index == cachedFilters.length
                              ? Wrap(
                                  children: <Widget>[
                                    Container(
                                        margin: EdgeInsets.only(top: 32,left: 8),
                                        width: 56,
                                        height: 56,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 1))
                                  ],
                                )
                              : InkWell(
                                  child: Container(
                                    padding: EdgeInsets.all(5.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        ContainerRectangle(
                                          memoryImage: MemoryImage(
                                            cachedFilters[
                                                widget.filters[index].name],
                                          ),
                                          backgroundColor: Colors.white,
                                        ),
//                                  _buildFilterThumbnail(
//                                      widget.filters[index], image, filename),
                                        SizedBox(
                                          height: 5.0,
                                        ),
                                        Text(
                                          widget.filters[index].name,
                                        )
                                      ],
                                    ),
                                  ),
                                  onTap: () => setState(() {
                                    _filter = widget.filters[index];
                                  }),
                                );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  _buildFilterThumbnail(Filter filter, imageLib.Image image, String filename) {
    if (cachedFilters[filter?.name ?? "_"] == null) {
      return FutureBuilder<List<int>>(
        future: compute(applyFilter, <String, dynamic>{
          "filter": filter,
          "image": image,
          "filename": filename,
        }),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.active:
            case ConnectionState.waiting:
              return ContainerRectangle(
                child: Center(
                  child: widget.loader,
                ),
                backgroundColor: Colors.white,
              );
            case ConnectionState.done:
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              cachedFilters[filter?.name ?? "_"] = snapshot.data;
              return ContainerRectangle(
                memoryImage: MemoryImage(
                  snapshot.data,
                ),
                backgroundColor: Colors.white,
              );
          }
          return null; // unreachable
        },
      );
    } else {
      return ContainerRectangle(
        memoryImage: MemoryImage(
          cachedFilters[filter?.name ?? "_"],
        ),
        backgroundColor: Colors.white,
      );
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/filtered_${_filter?.name ?? "_"}_$filename');
  }

  Future<File> saveFilteredImage() async {
    var imageFile = await _localFile;
    await imageFile.writeAsBytes(cachedFilters[_filter?.name ?? "_"]);
    return imageFile;
  }

  Widget _buildFilteredImage(
      Filter filter, imageLib.Image image, String filename) {
    if (cachedFilters[filter?.name ?? "_"] == null) {
      return FutureBuilder<List<int>>(
        future: compute(applyFilter, <String, dynamic>{
          "filter": filter,
          "image": image,
          "filename": filename,
        }),
        builder: (BuildContext context, AsyncSnapshot<List<int>> snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
              return widget.loader;
            case ConnectionState.active:
            case ConnectionState.waiting:
              return widget.loader;
            case ConnectionState.done:
              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));
              cachedFilters[filter?.name ?? "_"] = snapshot.data;
              return widget.circleShape
                  ? SizedBox(
                      height: MediaQuery.of(context).size.width / 3,
                      width: MediaQuery.of(context).size.width / 3,
                      child: Center(
                        child: CircleAvatar(
                          radius: MediaQuery.of(context).size.width / 3,
                          backgroundImage: MemoryImage(
                            snapshot.data,
                          ),
                        ),
                      ),
                    )
                  : Image.memory(
                      snapshot.data,
                      fit: BoxFit.contain,
                    );
          }
          return null; // unreachable
        },
      );
    } else {
      return widget.circleShape
          ? SizedBox(
              height: MediaQuery.of(context).size.width / 3,
              width: MediaQuery.of(context).size.width / 3,
              child: Center(
                child: CircleAvatar(
                  radius: MediaQuery.of(context).size.width / 3,
                  backgroundImage: MemoryImage(
                    cachedFilters[filter?.name ?? "_"],
                  ),
                ),
              ),
            )
          : Image.memory(
              cachedFilters[filter?.name ?? "_"],
              fit: widget.fit,
            );
    }
  }
}

///The global applyfilter function
List<int> applyFilter(Map<String, dynamic> params) {
  Filter filter = params["filter"];
  imageLib.Image image = params["image"];
  String filename = params["filename"];
  List<int> _bytes = image.getBytes();
  if (filter != null) {
    filter.apply(_bytes);
  }
  imageLib.Image _image =
      imageLib.Image.fromBytes(image.width, image.height, _bytes);
  _bytes = imageLib.encodeNamedImage(_image, filename);

  return _bytes;
}

///The global buildThumbnail function
List<int> buildThumbnail(Map<String, dynamic> params) {
  int width = params["width"];
  params["image"] = imageLib.copyResize(params["image"], width: width);
  return applyFilter(params);
}
