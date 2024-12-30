class _HomePageState extends State<HomePage> {
  // Deklarasi variabel
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  bool isComplete = false;
  Future<QuerySnapshot>? searchResultsFuture;

  // Fungsi initState
  @override
  void initState() {
    super.initState();
    getTodo();
  }

  // Fungsi untuk logout
  Future<void> _signOut() async {
    await _auth.signOut();
    runApp(MaterialApp(
      home: LoginPage(),
    ));
  }

  // Fungsi untuk membersihkan teks
  void cleartext() {
    _titleController.clear();
    _descriptionController.clear();
  }

  // Fungsi untuk mencari todo
  Future<void> searchResult(String textEntered) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("Todos")
        .where("title", isGreaterThanOrEqualTo: textEntered)
        .where("title", isLessThan: textEntered + 'z')
        .get();

    setState(() {
      searchResultsFuture = Future.value(querySnapshot);
    });
  }

  // Fungsi untuk menambahkan todo
  Future<void> addTodo() {
    return _firestore.collection('Todos').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'isComplete': isComplete,
      'uid': _auth.currentUser!.uid,
    }).catchError((error) => print('Failed to add todo: $error'));
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference todoCollection = _firestore.collection('Todos');
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Todo List'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout'),
                  content: Text('Apakah anda yakin ingin logout?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Tidak'),
                    ),
                    TextButton(
                      onPressed: () {
                        _signOut();
                      },
                      child: Text('Ya'),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (textEntered) {
                searchResult(textEntered);
                setState(() {
                  _searchController.text = textEntered;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _searchController.text.isEmpty
                  ? _firestore
                      .collection('Todos')
                      .where('uid', isEqualTo: user!.uid)
                      .snapshots()
                  : searchResultsFuture != null
                      ? searchResultsFuture!
                          .asStream()
                          .cast<QuerySnapshot<Map<String, dynamic>>>()
                      : Stream.empty(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                List<Todo> listTodo = snapshot.data!.docs.map((document) {
                  final data = document.data();
                  final String title = data['title'];
                  final String description = data['description'];
                  final bool isComplete = data['isComplete'];
                  final String uid = user!.uid;

                  return Todo(
                    description: description,
                    title: title,
                    isComplete: isComplete,
                    uid: uid,
                  );
                }).toList();
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: listTodo.length,
                  itemBuilder: (context, index) {
                    return ItemList(
                      todo: listTodo[index],
                      transaksiDocId: snapshot.data!.docs[index].id,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Tambah Todo'),
              content: SizedBox(
                width: 200,
                height: 100,
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(hintText: 'Judul todo'),
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(hintText: 'Deskripsi todo'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Batalkan'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text('Tambah'),
                  onPressed: () {
                    addTodo();
                    cleartext();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
