import 'package:flutter/material.dart';
import 'linkUpload.dart';

class LinkUploadPageWithURL extends LinkUploadPage {
  final String url;
  const LinkUploadPageWithURL({required this.url, super.key});

  @override
  State<LinkUploadPage> createState() => _LinkUploadPageWithURLState();
}

class _LinkUploadPageWithURLState extends LinkUploadPageState {
  @override
  void initState() {
    super.initState();
    linkController.text = (widget as LinkUploadPageWithURL).url;
  }
}
