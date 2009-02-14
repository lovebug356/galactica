namespace Config {
  [CCode (cheader_filename="config.h",cname="VERSION")]
  public const string VERSION;
  [CCode (cheader_filename="config.h",cname="PACKAGE_DATADIR")]
  public const string PACKAGE_DATADIR;
}
